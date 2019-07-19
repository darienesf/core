local pipeline = import 'pipeline.libsonnet';

local trigger = {
  ref: [
    'refs/heads/master',
    'refs/heads/stable10',
    'refs/heads/drone-jsonnet',
    'refs/heads/release-*',
    'refs/tags/**',
    'refs/pull/**',
  ],
};

local style_deps = [
  'install-dependencies',
];

local unit_deps = style_deps + [
  'coding-standard',
  'phan-php7.1',
  // 'phan-php7.2',
  // 'phan-php7.3',
  'stan-php7.1',
];

local pipelines = [
  # dependencies
  pipeline.install(trigger=trigger),

  # codestyle
  pipeline.standard(
    trigger=trigger,
    depends_on=style_deps
  ),
  pipeline.phan(
    php='7.1',
    trigger=trigger,
    depends_on=style_deps
  ),
  // pipeline.phan(
  //   php='7.2',
  //   trigger=trigger,
  //   depends_on=style_deps
  // ),
  // pipeline.phan(
  //   php='7.3',
  //   trigger=trigger,
  //   depends_on=style_deps
  // ),
  pipeline.stan(
    php='7.1',
    trigger=trigger,
    depends_on=style_deps
  ),

  # frontend
  pipeline.javascript(
    trigger=trigger,
    depends_on=unit_deps
  ),

  # Unit Tests
  # PHP 7.1
  pipeline.phpunit(
    php='7.1',
    db='mysql:5.5',
    coverage=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    # mb4 support, with innodb_file_format=Barracuda
    db='mysql:5.7',
    // coverage=true, ??
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    # mb4 support by default
    db='mysql:8.0',
    coverage=false,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    db='postgres:9.4',
    coverage=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    db='postgres:10.3',
    coverage=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    # mb4 support by default
    db='mariadb:10.3',
    coverage=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    db='oracle',
    coverage=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    db='sqlite',
    coverage=true,
    trigger=trigger,
    depends_on=unit_deps
  ),

  # PHP 7.2

  # Not in 0.8 .drone.yml
  // pipeline.phpunit(
  //   php='7.2',
  //   db='mysql:5.5',
  //   coverage=true,
  //   trigger=trigger,
  //   depends_on=unit_deps
  // ),
  // pipeline.phpunit(
  //   php='7.2',
  //   db='postgres:9.4',
  //   coverage=true,
  //   trigger=trigger,
  //   depends_on=unit_deps
  // ),

  pipeline.phpunit(
    php='7.2',
    db='sqlite',
    // coverage=true, ??
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.2',
    db='mariadb',
    // coverage=false, ??
    trigger=trigger,
    depends_on=unit_deps
  ),

  # php-7.3
  pipeline.phpunit(
    php='7.3',
    db='sqlite',
    // coverage=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.3',
    db='mariadb',
    // coverage=true, ??
    trigger=trigger,
    depends_on=unit_deps
  ),
  
  # Not in 0.8 .drone.yml
  // pipeline.phpunit(
  //   php='7.3',
  //   db='mysql:5.5',
  //   coverage=true,
  //   trigger=trigger,
  //   depends_on=unit_deps
  // ),
  // pipeline.phpunit(
  //   php='7.3',
  //   db='postgres:9.4',
  //   coverage=true,
  //   trigger=trigger,
  //   depends_on=unit_deps
  // ),


  # Files External
  pipeline.phpunit(
    php='7.1',
    db='sqlite',
    coverage=true,
    external='webdav',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    db='sqlite',
    coverage=true,
    external='samba',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    php='7.1',
    db='sqlite',
    coverage=true,
    external='smb_windows',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.phpunit(
    pipeline_name='phpunit-php7.1-mariadb10.3-swift-external',
    php='7.1',
    db='mariadb:10.3',
    coverage=true,
    external='swift',
    trigger=trigger,
    depends_on=unit_deps
  ),

  # Primary Objectstorage
  pipeline.phpunit(
    pipeline_name='phpunit-php7.1-mariadb10.3-swift-objectstore',
    php='7.1',
    db='sqlite',
    coverage=true,
    primary_object='swift',
    object='swift',
    external='swift',
    trigger=trigger,
    depends_on=unit_deps
  ),

  # files_primary_s3
  pipeline.phpunit(
    php='7.1',
    db='sqlite',
    coverage=true,
    primary_object='files_primary_s3',
    object='scality',
    trigger=trigger,
    depends_on=unit_deps
  ),

  # API Acceptance tests
  pipeline.behat(
    suite='apiMain',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiAuth',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiAuthOcs',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiCapabilities',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiComments',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiFavorites',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiFederation',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiProvisioning-v1',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiProvisioning-v2',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiProvisioningGroups-v1',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiProvisioningGroups-v2',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiSharees',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiShareManagement',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiShareManagementBasic',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiShareOperations',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiShareReshare',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiShareUpdate',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiSharingNotifications',
    type='api',
    install_notifications_app=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiTags',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiTrashbin',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiVersions',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiWebdavLocks',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiWebdavLocks2',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiWebdavMove',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiWebdavOperations',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiWebdavProperties',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='apiWebdavUpload',
    type='api',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='cliAppManagement',
    type='local-cli',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='cliProvisioning',
    type='cli',
    email=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='cliMain',
    type='cli',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='cliBackground',
    type='cli',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    suite='cliTrashbin',
    type='cli',
    trigger=trigger,
    depends_on=unit_deps
  ),

  # chrome
  pipeline.behat(
    browser='chrome',
    suite='webUIAdminSettings',
    type='webui',
    email=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIComments',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUICreateDelete',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIFavorites',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIFiles',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUILogin',
    type='webui',
    email=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIMoveFilesFolders',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIPersonalSettings',
    type='webui',
    email=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIRenameFiles',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIRenameFolders',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIRestrictSharing',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUISharingAcceptShares',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUISharingAutocompletion',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUISharingExternal',
    type='webui',
    email=true,
    federation_oc_version='daily-stable10-qa',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUISharingInternalGroups',
    type='webui',
    email=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUISharingInternalUsers',
    type='webui',
    email=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUISharingNotifications',
    type='webui',
    email=true,
    install_notifications_app=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUISharingPublic',
    type='webui',
    email=true,
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUITags',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUITrashbin',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIUpload',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIWebdavLocks',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    browser='chrome',
    suite='webUIWebdavLockProtection',
    type='webui',
    trigger=trigger,
    depends_on=unit_deps
  ),

  # Firefox
  pipeline.behat(
    pipeline_name='behat-firefox-smokeTest-1/3',
    browser='firefox',
    type='webui',
    filter='@smokeTest&&~@notifications-app-required',
    num='1/3',
    email=true,
    server_protocol='http',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    pipeline_name='behat-firefox-smokeTest-2/3',
    browser='firefox',
    type='webui',
    filter='@smokeTest&&~@notifications-app-required',
    num='2/3',
    email=true,
    server_protocol='http',
    trigger=trigger,
    depends_on=unit_deps
  ),
  pipeline.behat(
    pipeline_name='behat-firefox-smokeTest-3/3',
    browser='firefox',
    type='webui',
    filter='@smokeTest&&~@notifications-app-required',
    num='3/3',
    email=true,
    server_protocol='http',
    trigger=trigger,
    depends_on=unit_deps
  ),

  pipeline.dav(
    suite='caldav',
    php='7.1',
    db='mariadb',
    trigger=trigger,
    depends_on=unit_deps
  ),

  pipeline.dav(
    suite='carddav',
    php='7.1',
    db='mariadb',
    trigger=trigger,
    depends_on=unit_deps
  ),

  pipeline.dav(
    suite='caldav-old-endpoint',
    php='7.1',
    db='mariadb',
    trigger=trigger,
    depends_on=unit_deps
  ),

  pipeline.dav(
    suite='carddav-old-endpoint',
    php='7.1',
    db='mariadb',
    trigger=trigger,
    depends_on=unit_deps
  ),

  pipeline.litmus(
    php='7.1',
    depends_on=unit_deps,
  ),
];


local pipeline_names = std.filterMap(function(p) p.kind == 'pipeline', function(p) p.name, pipelines);

pipelines + [
  pipeline.notify(
    name='failure',
    message='Tests failed',
    include_events=['push', 'tag'],
    depends_on=pipeline_names,
    status=['failure'],
  )
]
