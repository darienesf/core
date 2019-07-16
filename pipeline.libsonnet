local optionalSuffix(value) = if value != '' then '-' + value else value;

local dbServices = {
  mariadb(version='')::
    local v = if version != '' then version else '10.2';
    [{
      name: 'mariadb',
      image: 'mariadb:' + v,
      environment: {
        MYSQL_USER: 'owncloud',
        MYSQL_PASSWORD: 'owncloud',
        MYSQL_DATABASE: 'owncloud',
        MYSQL_ROOT_PASSWORD: 'owncloud',
      },
    }],

  mysql(version='')::
    local v = if version != '' then version else '5.5';
    [{
      name: 'mysql',
      image: 'mysql:' + v,
      environment: {
        MYSQL_USER: 'owncloud',
        MYSQL_PASSWORD: 'owncloud',
        MYSQL_DATABASE: 'owncloud',
        MYSQL_ROOT_PASSWORD: 'owncloud',
      },
      # see http://php.net/manual/en/mysqli.requirements.php
      [if version == '8.0' then 'command']: ['--default-authentication-plugin=mysql_native_password'],
    }],

  postgres(version='')::
    local v = if version != '' then version else '9.4';
    [{
      name: 'postgres',
      image: 'postgres:' + v,
      environment: {
        POSTGRES_USER: 'owncloud',
        POSTGRES_PASSWORD: 'owncloud',
        POSTGRES_DB: 'owncloud',
      },
    }],

  oracle(version='')::
    [{
      name: 'oracle',
      image: 'deepdiver/docker-oracle-xe-11g:2.0',
      environment: {
        ORACLE_DISABLE_ASYNCH_IO: true,
      },
    }],

  sqlite(version='')::
    [],

  get(db, version)::
    if db != '' then $[db](version) else [],
};

local owncloud_services(server_protocol, image) = if server_protocol == 'http' then [{
    name: 'server-http',
    image: image,
    pull: 'always',
    environment: {
      APACHE_WEBROOT: '/drone/src/',
    },
    command: [ '/usr/local/bin/apachectl', '-e', 'debug' , '-D', 'FOREGROUND' ]
  }] else if server_protocol == 'https' then [{
    name: 'server-https',
    image: image,
    pull: 'always',
    environment: {
      APACHE_WEBROOT: '/drone/src/',
      APACHE_CONFIG_TEMPLATE: 'ssl',
      APACHE_SSL_CERT_CN: 'server-https',
      APACHE_SSL_CERT: '/drone/server.crt',
      APACHE_SSL_KEY: '/drone/server.key',
    },
    command: [ '/usr/local/bin/apachectl', '-e', 'debug' , '-D', 'FOREGROUND' ]
  }] else [];


local behatSteps = {
  api(suite, image, server_protocol, browser)::
    [{
      name: 'api-acceptance-tests',
      image: image,
      pull: 'always',
      environment: {
        TEST_SERVER_URL: server_protocol + '://server-' + server_protocol,
        BEHAT_SUITE: suite,
      },
      commands: [
        'touch /drone/saved-settings.sh',
        '. /drone/saved-settings.sh',
        'make test-acceptance-api TESTING_REMOTE_SYSTEM=true',
      ],
    }],

  cli(suite, image, server_protocol, browser)::
    [{
      name: 'cli-acceptance-tests',
      image: image,
      pull: 'always',
      environment: {
        MAILHOG_HOST: 'email',
        TEST_SERVER_URL: server_protocol + '://server-' + server_protocol,
        BEHAT_SUITE: suite,
      },
      commands: [
        'touch /drone/saved-settings.sh',
        '. /drone/saved-settings.sh',
        'make test-acceptance-cli TESTING_REMOTE_SYSTEM=true',
      ],
    }],


  'local-cli'(suite,image, server_protocol, browser)::
    [{
      name: 'cli-acceptance-tests',
      image: image,
      pull: 'always',
      environment: {
        MAILHOG_HOST: 'email',
        TEST_SERVER_URL: server_protocol + '://server-' + server_protocol,
        BEHAT_SUITE: suite,
      },
      commands: [
        'touch /drone/saved-settings.sh',
        '. /drone/saved-settings.sh',
        'make',
        'su-exec www-data ./tests/acceptance/run.sh --type cli',
      ],
    }],

  webui(suite, image, server_protocol, browser)::
    [{
      name: 'cli-acceptance-tests',
      image: image,
      pull: 'always',
      environment: {
        TEST_SERVER_URL: server_protocol + '://server-' + server_protocol,
        BEHAT_SUITE: suite,
        BROWSER: browser,
        SELENIUM_HOST: browser,
        SELENIUM_PORT: 4444,
        PLATFORM: 'Linux',
        MAILHOG_HOST: 'email',
      },
      commands: [
        'touch /drone/saved-settings.sh',
        '. /drone/saved-settings.sh',
        'make test-acceptance-webui TESTING_REMOTE_SYSTEM=true',
      ],
    }],

  get(type, suite, image, server_protocol, browser)::
     if type != '' then $[type](suite, image, server_protocol, browser) else [],
};


{
  cache(settings={})::
    local step_name = "cache-" + if "restore" in settings then "restore" else if "rebuild" in settings then "rebuild" else if "flush" in settings then "flush" else "unknown";

    {
      name: step_name,
      image: 'plugins/s3-cache:1',
      pull: 'always',
      settings: {
        endpoint: {
          from_secret: 'cache_s3_endpoint'
        },
        access_key: {
          from_secret: 'cache_s3_access_key'
        },
        secret_key: {
          from_secret: 'cache_s3_secret_key'
        },
      } + settings,
      when: {
        instance: [
          'drone.owncloud.services',
          'drone.owncloud.com',
        ],
      } + if std.objectHas(settings, 'restore') then {} else { event: ['push'] },
    },

  yarn(image='owncloudci/php:7.1')::
    {
      name: 'yarn',
      image: image,
      pull: 'always',
      environment: {
        NPM_CONFIG_CACHE: '/drone/src/.cache/npm',
        YARN_CACHE_FOLDER: '/drone/src/.cache/yarn',
        bower_storage__packages: '/drone/src/.cache/bower',
      },
      commands: [
        'make install-nodejs-deps',
      ],
    },

  composer(image='owncloudci/php:7.1')::
    {
      name: 'composer',
      image: image,
      pull: 'always',
      environment: {
        COMPOSER_HOME: '/drone/src/.cache/composer',
      },
      commands: [
        'make install-composer-deps',
      ],
    },

  vendorbin(image='owncloudci/php:7.1')::
    {
      name: 'vendorbin',
      image: image,
      pull: 'always',
      environment: {
        COMPOSER_HOME: '/drone/src/.cache/composer',
      },
      commands: [
        'make vendor-bin-deps',
      ],
    },

  installServer(image='owncloudci/php:7.1', db_name='', server_protocol='https')::
    {
      name: 'install-server',
      image: image,
      pull: 'always',
      environment: {
        DB_TYPE: db_name,
      },
      commands: [
        './tests/drone/install-server.sh',
        'php occ a:l',
        'php occ config:system:set trusted_domains 1 --value=server-' + server_protocol,
        'php occ config:system:set trusted_domains 2 --value=federated-' + server_protocol,
        'php occ log:manage --level 2',
        'php occ config:list',
        'php occ security:certificates:import /drone/server.crt',
        'php occ security:certificates:import /drone/federated.crt',
        'php occ security:certificates',
      ],
    },

  installTestingApp(image='owncloudci/php:7.1')::
    {
      name: 'install-testing-app',
      image: image,
      pull: 'always',
      commands: [
        'git clone https://github.com/owncloud/testing.git $$DRONE_WORKSPACE/apps-external/testing',
        'php occ a:l',
        'php occ a:e testing',
        'php occ a:l',
      ],
    },

  prepareObjectStore(image, object)::
    {
      name: 'prepare-objectstore',
      image: image,
      pull: 'always',
      environment: {
        OBJECTSTORE: object
      },
      commands: [
        'cd /drone/src/apps',
        'git clone https://github.com/owncloud/files_primary_s3.git',
        'cd files_primary_s3',
        'composer install',
        'cp tests/drone/' + object + '.config.php /drone/src/config',
        'cd /drone/src',
        'php occ a:l',
        'php occ a:e files_primary_s3',
        'php occ a:l',
        'php ./occ s3:create-bucket owncloud --accept-warning',
      ],
    },

  fixPermissions(image='owncloudci/php:7.1', path='/drone/src')::
    {
      name: 'fix-permissions',
      image: image,
      pull: 'always',
      commands: [
        'chown www-data "' + path + '" -R',
      ],
    },

  install(trigger={}, depends_on=[])::
    {
      kind: 'pipeline',
      name: 'install-dependencies',
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:7.1'),
        $.vendorbin(image='owncloudci/php:7.1'),
        $.yarn(image='owncloudci/php:7.1'),
        $.cache({ rebuild: true, mount: ['.cache'] }),
        $.cache({ flush: true, flush_age: 14 }),
      ],
      trigger: trigger,
      depends_on: depends_on,
    },

  standard(trigger={}, depends_on=[])::
    {
      kind: 'pipeline',
      name: 'coding-standard',
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:7.1'),
        $.vendorbin(image='owncloudci/php:7.1'),
        $.yarn(image='owncloudci/php:7.1'),
        {
          name: 'test',
          image: 'owncloudci/php:7.3',
          pull: 'always',
          commands: [
            'make test-php-style',
          ],
        },
      ],
      trigger: trigger,
      depends_on: depends_on,
    },

  phan(php='', trigger={}, depends_on=[])::
    {
      kind: 'pipeline',
      name: 'phan-php' + php,
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:' + php),
        $.vendorbin(image='owncloudci/php:' + php),
        $.yarn(image='owncloudci/php:' + php),
        {
          name: 'test',
          image: 'owncloudci/php:' + php,
          pull: 'always',
          commands: [
            'make test-php-phan',
          ],
        },
      ],
      trigger: trigger,
      depends_on: depends_on,
    },

  stan(php='', trigger={}, depends_on=[])::
    {
      kind: 'pipeline',
      name: 'stan-php' + php,
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:' + php),
        $.vendorbin(image='owncloudci/php:' + php),
        $.yarn(image='owncloudci/php:' + php),
        $.installServer(image='owncloudci/php:' + php),
        {
          name: 'test',
          image: 'owncloudci/php:' + php,
          pull: 'always',
          commands: [
            'make test-php-phpstan',
          ],
        },
      ],
      trigger: trigger,
      depends_on: depends_on
    },

  javascript(trigger={}, depends_on=[])::
    {
      kind: 'pipeline',
      name: 'test-javascript',
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:7.1'),
        $.vendorbin(image='owncloudci/php:7.1'),
        $.yarn(image='owncloudci/php:7.1'),
        {
          name: 'test',
          image: 'owncloudci/php:7.1',
          pull: 'always',
          commands: [
            'make test-js',
          ],
        },
        // {
        //   name: 'codecov',
        //   image: 'plugins/codecov:2',
        //   pull: 'always',
        //   environment: {
        //     CODECOV_TOKEN: {
        //       from_secret: 'codecov_token',
        //     },
        //   },
        //   settings: {
        //     flags: [
        //       'javascript',
        //     ],
        //     paths: [
        //       'tests/output/coverage',
        //     ],
        //     files: [
        //       '*.xml',
        //     ],
        //   },
        // },
      ],
      trigger: trigger,
      depends_on: depends_on,
    },

  phpunit(php='', db='', coverage=false, external='', primary_object='', object='', trigger={}, depends_on=[], pipeline_name='')::
    local database_split = std.split(db, ':');

    local database_name = database_split[0];
    local database_version = if std.length(database_split) == 2 then database_split[1] else '';

    {
      kind: 'pipeline',
      name: if pipeline_name != '' then pipeline_name else 'phpunit-php' + php + '-' + std.join('', database_split) + optionalSuffix(external) + optionalSuffix(primary_object) + optionalSuffix(object),
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:7.1'),
        $.vendorbin(image='owncloudci/php:7.1'),
        $.yarn(image='owncloudci/php:7.1'),
        $.installServer(image='owncloudci/php:' + php, db_name=database_name),
        $.installTestingApp(image='owncloudci/php:' + php),
        (if object == 'files_primary_s3' then $.prepareObjectStore(image='owncloudci/php:' + php, object=object)),
        {
          name: 'test',
          image: 'owncloudci/php:' + php,
          pull: 'always',
          environment: {
            FILES_EXTERNAL_TYPE: (if external == 'webdav' then 'webdav_apache' else (if external == 'samba' then 'smb_samba' else external)),
            COVERAGE: coverage,
            PRIMARY_OBJECTSTORE: primary_object,
            DB_TYPE: database_name,

          },
          commands: [
            './tests/drone/test-phpunit.sh',
          ],
        },
      ],
      services: [
        (if external == 'webdav' then {
          name: 'apache-webdav',
          image: 'owncloudci/php',
          pull: 'always',
          environment: {
            APACHE_CONFIG_TEMPLATE: 'webdav',
          },
          command: [ '/usr/local/bin/apachectl', '-D', 'FOREGROUND' ]
        }),
        (if external == 'samba' then {
          name: 'smb-samba',
          image: 'owncloudci/samba',
          pull: 'always',
          command: ['-u', 'test;test', '-s', 'public;/tmp;yes;no;no;test;none;test', '-S'],
        }),
        (if external == 'swift' then {
          name: 'ceph',
          image: 'owncloudci/ceph',
          pull: 'always',
          environment: {
            KEYSTONE_PUBLIC_PORT: 5034,
            KEYSTONE_ADMIN_USER: 'test',
            KEYSTONE_ADMIN_PASS: 'testing',
            KEYSTONE_ADMIN_TENANT: 'testtenant',
            KEYSTONE_ENDPOINT_REGION: 'testregion',
            KEYSTONE_SERVICE: 'testceph',
            OSD_SIZE: 500,
          },
        }),
        (if object == 'scality' then {
          name: 'scality',
          image: 'owncloudci/scality-s3server',
          pull: 'always',
          environment: {
            HOST_NAME: 'scality',
          },
        })
      ] + dbServices.get(database_name, database_version),
      trigger: trigger,
      depends_on: depends_on,
    },

  behat(browser='', suite='', type='', filter='', num='', email=false, server_protocol='https', install_notifications_app=false, trigger={}, depends_on=[], pipeline_name='')::
    local db_name = 'mariadb';
    local db_version = '';

    local image = 'owncloudci/php:7.1';

    {
      kind: 'pipeline',
      name: if pipeline_name != '' then pipeline_name else'behat' + optionalSuffix(browser) + optionalSuffix(suite) + optionalSuffix(filter) + optionalSuffix(num),
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      workspace: {
        base: '/drone',
        path: 'src',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image=image),
        $.vendorbin(image=image),
        $.yarn(image=image),
        $.installServer(image=image, db_name=db_name),
        $.installTestingApp(image=image),
        (if install_notifications_app then {
          name: 'install-notifications-app',
          image: image,
          pull: 'always',
          commands: [
            'git clone https://github.com/owncloud/notifications.git apps/notifications',
            'php occ a:e notifications',
          ],
        }),
        $.fixPermissions(image=image),
      ] + behatSteps.get(type=type, suite=suite, image=image, server_protocol=server_protocol, browser=browser),
      services: [
        (if email then {
          name: 'email',
          pull: 'always',
          image: 'mailhog/mailhog',
        }),
      ] + owncloud_services(server_protocol=server_protocol, image=image) + dbServices.get(db_name, db_version),
      trigger: trigger,
      depends_on: depends_on,
    },

  dav(suite, php, db, trigger={}, depends_on=[], pipeline_name='')::
    local database_split = std.split(db, ':');

    local database_name = database_split[0];
    local database_version = if std.length(database_split) == 2 then database_split[1] else '';

    {
      kind: 'pipeline',
      name: suite + '-php' + php + '-' + std.join('', database_split),
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:7.1'),
        $.vendorbin(image='owncloudci/php:7.1'),
        $.yarn(image='owncloudci/php:7.1'),
        $.installServer(image='owncloudci/php:' + php, db_name=database_name),
        {
          name: suite + '-install',
          image: 'owncloudci/php:' + php,
          pull: 'always',
          commands: [
            'bash apps/dav/tests/ci/' + suite + '/install.sh',
          ],
        },
        $.fixPermissions(image='owncloudci/php:7.1'),
        {
          name: suite + '-test',
          image: 'owncloudci/php:' + php,
          pull: 'always',
          commands: [
            'bash apps/dav/tests/ci/' + suite + '/script.sh',
          ],
        },
      ],
      services: dbServices.get(database_name, database_version),
      trigger: trigger,
      depends_on: depends_on,
    },

  litmus(php, db='', trigger={}, depends_on=[])::
    local database_split = std.split(db, ':');

    local database_name = database_split[0];
    local database_version = if std.length(database_split) == 2 then database_split[1] else '';

    {
      kind: 'pipeline',
      name: 'litmus',
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:7.1'),
        $.vendorbin(image='owncloudci/php:7.1'),
        $.yarn(image='owncloudci/php:7.1'),
        $.installServer(image='owncloudci/php:' + php, db_name=database_name),
        {
          name: 'litmus-setup',
          image: 'owncloudci/php:' + php,
          pull: 'always',
          commands: [
            'echo "Create local mount ...."',
            'mkdir -p /drone/src/work/local_storage',
            'php occ app:enable files_external',
            'php occ config:system:set files_external_allow_create_new_local --value=true',
            'php occ config:app:set core enable_external_storage --value=yes',
            'php occ files_external:create local_storage local null::null -c datadir=/drone/src/work/local_storage',
            'echo "Sharing a folder .."',
            'OC_PASS=123456 php occ user:add --password-from-env user1',
            'chown www-data /drone/src -R',
            'curl -k -s -u user1:123456 -X MKCOL "https://server-https/remote.php/webdav/new_folder"',
            'curl -k -s -u user1:123456 "https://server-https/ocs/v2.php/apps/files_sharing/api/v1/shares" --data \'path=/new_folder&shareType=0&permissions=15&name=new_folder&shareWith=admin\'',
          ],
        },
        $.fixPermissions(image='owncloudci/php:7.1'),
        {
          name: 'litmus-old-endpoint',
          image: 'owncloud/litmus',
          pull: 'always',
          environment: {
            LITMUS_URL: 'https://server-https/remote.php/webdav',
            LITMUS_USERNAME: 'admin',
            LITMUS_PASSWORD: 'admin',
          },
        },
        {
          name: 'litmus-new-endpoint',
          image: 'owncloud/litmus',
          pull: 'always',
          environment: {
            LITMUS_URL: 'https://server-https/remote.php/dav/files/admin',
            LITMUS_USERNAME: 'admin',
            LITMUS_PASSWORD: 'admin',
          },
        },
        {
          name: 'litmus-new-endpoint-mount',
          image: 'owncloud/litmus',
          pull: 'always',
          environment: {
            LITMUS_URL: 'https://server-https/remote.php/dav/files/admin/local_storage/',
            LITMUS_USERNAME: 'admin',
            LITMUS_PASSWORD: 'admin',
          },
        },
        {
          name: 'litmus-old-endpoint-mount',
          image: 'owncloud/litmus',
          pull: 'always',
          environment: {
            LITMUS_URL: 'https://server-https/remote.php/webdav/local_storage/',
            LITMUS_USERNAME: 'admin',
            LITMUS_PASSWORD: 'admin',
          },
        },
        {
          name: 'litmus-new-endpoint-shared',
          image: 'owncloud/litmus',
          pull: 'always',
          environment: {
            LITMUS_URL: 'https://server-https/remote.php/dav/files/admin/new_folder/',
            LITMUS_USERNAME: 'admin',
            LITMUS_PASSWORD: 'admin',
          },
        },
        {
          name: 'litmus-old-endpoint-shared',
          image: 'owncloud/litmus',
          pull: 'always',
          environment: {
            LITMUS_URL: 'https://server-https/remote.php/webdav/new_folder/',
            LITMUS_USERNAME: 'admin',
            LITMUS_PASSWORD: 'admin',
          },
        },
      ],
      services: owncloud_services(server_protocol='https', image='owncloudci/php:7.1'),
      trigger: trigger,
      depends_on: depends_on,
    },
}
