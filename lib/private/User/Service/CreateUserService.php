<?php
/**
 * @author Sujith Haridasan <sharidasan@owncloud.com>
 *
 * @copyright Copyright (c) 2019, ownCloud GmbH
 * @license AGPL-3.0
 *
 * This code is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License, version 3,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License, version 3,
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 *
 */

namespace OC\User\Service;

use OCP\IGroupManager;
use OCP\ILogger;
use OCP\IUser;
use OCP\IUserManager;
use OCP\IUserSession;
use OCP\Security\ISecureRandom;
use OCP\User\Exceptions\CannotCreateUserException;
use OCP\User\Exceptions\InvalidEmailException;
use OCP\User\Exceptions\UserAlreadyExistsException;

class CreateUserService {
	/** @var IUserSession  */
	private $userSession;
	/** @var IGroupManager  */
	private $groupManager;
	/** @var IUserManager  */
	private $userManager;
	/** @var ISecureRandom  */
	private $secureRandom;
	/** @var ILogger  */
	private $logger;
	/** @var UserSendMailService  */
	private $userSendMailService;
	/** @var PasswordGeneratorService  */
	private $passwordGeneratorService;

	/**
	 * CreateUserService constructor.
	 *
	 * @param IUserSession $userSession
	 * @param IGroupManager $groupManager
	 * @param IUserManager $userManager
	 * @param ISecureRandom $secureRandom
	 * @param ILogger $logger
	 * @param UserSendMailService $userSendMailService
	 * @param PasswordGeneratorService $passwordGeneratorService
	 */
	public function __construct(IUserSession $userSession, IGroupManager $groupManager,
								IUserManager $userManager, ISecureRandom $secureRandom,
								ILogger $logger, UserSendMailService $userSendMailService,
								PasswordGeneratorService $passwordGeneratorService) {
		$this->userSession = $userSession;
		$this->groupManager = $groupManager;
		$this->userManager = $userManager;
		$this->secureRandom = $secureRandom;
		$this->logger = $logger;
		$this->userSendMailService = $userSendMailService;
		$this->passwordGeneratorService = $passwordGeneratorService;
	}

	/**
	 * @param string $username
	 * @param string $password
	 * @param string $email
	 * @return bool|IUser
	 * @throws CannotCreateUserException
	 * @throws InvalidEmailException
	 * @throws UserAlreadyExistsException
	 */
	public function createUser($username, $password, $email='') {
		if ($email !== '' && !$this->userSendMailService->validateEmailAddress($email)) {
			throw new InvalidEmailException("Invalid mail address");
		}

		if ($this->userManager->userExists($username)) {
			throw new UserAlreadyExistsException('A user with that name already exists.');
		}

		try {
			if (($password === '') && ($email !== '')) {
				/**
				 * Generate a random password as we are going to have this
				 * use one time. The new user has to reset it using the link
				 * from email.
				 */
				$password = $this->passwordGeneratorService->createPassword();
			}
			$user = $this->userManager->createUser($username, $password);
		} catch (\Exception $exception) {
			throw new CannotCreateUserException("Unable to create user due to exception: {$exception->getMessage()}");
		}

		if ($user === false) {
			throw new CannotCreateUserException('Unable to create user.');
		}

		/**
		 * Send new user mail only if a mail is set
		 */
		if ($email !== '') {
			$user->setEMailAddress($email);
			try {
				$this->userSendMailService->generateTokenAndSendMail($username, $email);
			} catch (\Exception $e) {
				$this->logger->error("Can't send new user mail to $email: " . $e->getMessage(), ['app' => 'settings']);
			}
		}

		return $user;
	}

	/**
	 * @param IUser $user
	 * @param array $groups
	 * @param bool $checkInGroup
	 * @return array
	 */
	public function addUserToGroups(IUser $user, array $groups= [], $checkInGroup = true) {
		$failedToAdd = [];

		foreach ($groups as $groupName) {
			$groupObject = $this->groupManager->get($groupName);

			if (empty($groupObject)) {
				$groupObject = $this->groupManager->createGroup($groupName);
			}
			$groupObject->addUser($user);
			if ($checkInGroup && !$this->groupManager->isInGroup($user->getUID(), $groupName)) {
				$failedToAdd[] = $groupName;
			} else {
				$this->logger->info('Added userid '.$user->getUID().' to group '.$groupName, ['app' => 'ocs_api']);
			}
		}
		return $failedToAdd;
	}

	/**
	 * Check if the user exist
	 * @param string $uid
	 * @return bool
	 */
	public function userExists($uid) {
		return $this->userManager->userExists($uid);
	}
}
