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
        {
          name: 'codecov',
          image: 'plugins/codecov:2',
          pull: 'always',
          environment: {
            CODECOV_TOKEN: {
              from_secret: 'codecov_token',
            },
          },
          settings: {
            flags: [
              'javascript',
            ],
            paths: [
              'tests/output/coverage',
            ],
            files: [
              '*.xml',
            ],
          },
        },
      ],
      trigger: trigger,
      depends_on: depends_on,
    },

  phpunit(php='', db='', coverage=false, external='', object='', trigger={}, depends_on=[])::
    local database_split = std.split(db, ':');

    local database_name = database_split[0];
    local database_version = database_split[1];

    local pipeline_name = 'phpunit-php' + php + '-' + std.join('', database_split) + optionalSuffix(external) + optionalSuffix(object);

    {
      kind: 'pipeline',
      name: pipeline_name,
      platform: {
        os: 'linux',
        arch: 'amd64',
      },
      environment: {
        FILES_EXTERNAL_TYPE: external,
        COVERAGE: coverage,
        PRIMARY_OBJECTSTORE: object,
      },
      steps: [
        $.cache({ restore: true }),
        $.composer(image='owncloudci/php:7.1'),
        $.vendorbin(image='owncloudci/php:7.1'),
        $.yarn(image='owncloudci/php:7.1'),
        $.installServer(image='owncloudci/php:' + php, db_name=database_name),
        $.installTestingApp(image='owncloudci/php:' + php),
        {
          name: 'test',
          image: 'owncloudci/php:' + php,
          pull: 'always',
          commands: [
            './tests/drone/test-phpunit.sh',
          ],
        },
      ],
      services: dbServices.get(database_name, database_version),
      trigger: trigger,
      depends_on: depends_on,
    },

  behat(browser='', suite='', filter='', num='', trigger={}, depends_on=[], pipeline_name='')::
    {
      kind: 'pipeline',
      name: if pipeline_name != '' then pipeline_name else'behat' + optionalSuffix(browser) + optionalSuffix(suite) + optionalSuffix(filter) + optionalSuffix(num),
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

          ],
        },
      ],
      trigger: trigger,
      depends_on: depends_on,
    },
}
