{{--
 *
 * Deploy Web App
 *
 * $ envoy run deploy [--branch=master]
 *
 * ## list all tasks
 * $ envoy tasks
 *
 --}}

@servers(['web' => 'www@127.0.0.1'])

@setup
    $repo = 'path/to/repo.git';

    $branch = isset($branch) ? $branch : 'master';

    $wwwRoot = '/data/www';
    $repoName = preg_replace('#\\.git$#i', '', pathinfo($repo, PATHINFO_BASENAME));
    $prefix = ($branch == 'master' ? '' : $branch.'-');

    $path = rtrim($wwwRoot, '/')."/{$prefix}{$repoName}";
@endsetup

@macro('deploy')
    start
    git
    composer
    end
@endmacro

@task('start')
    echo "====== Deploying [{{ $branch }}] to \"{{ $path }}\"..."
@endtask

@task('end')
    echo "====== Finished deploying \"{{ $repoName }}\"."
@endtask

@task('git')
    if [ ! -d "{{ $path }}" ]; then
        git clone {{ $repo }} --branch={{ $branch }} --single-branch --depth=1 "{{ $path }}"
    else
        cd "{{ $path }}"
        git pull origin {{ $branch }}
    fi
@endtask

@task('composer')
    if [ -f "{{ $path }}/composer.json" ]; then
        cd "{{ $path }}"
        composer install --no-dev --no-interaction --profile
        composer dump-autoload --optimize
    fi
@endtask

@task('laravel')
    if [ ! -d "{{ $path }}" ]; then
        git clone {{ $repo }} --branch={{ $branch }} --single-branch --depth=1 "{{ $path }}"
        cd "{{ $path }}"
        composer install --no-dev --no-interaction --profile
    fi

    cd "{{ $path }}"

    if [ ! -f ".env" ]; then
        echo "====== [Error] There is no .env file."
        exit 1
    fi

    if [ -f "storage/framework/down" ]; then
        APP_DOWN=1
        echo "====== [Warning] Application is in maintenance mode."
    else
        php artisan down
    fi

    git pull origin {{ $branch }}

    rm -rf bootstrap/cache/*
    composer install --no-dev --no-interaction --profile

    php artisan config:cache
    php artisan route:cache
    # php artisan migrate --force

    if [[ APP_DOWN != 1 ]]; then
        php artisan up
    fi

    php artisan queue:restart

@endtask

@task('queue')
    if [ -d "{{ $path }}" ]; then
        cd "{{ $path }}"
        php artisan queue:restart
    fi
@endtask

@task('backup-db')
    cd "{{ $path }}"

    php artisan db:backup --database=mysql \
        --destination=local \
        --compression=gzip \
        --destinationPath=`date +\%Y-%m-%d__%H:%M:%S.sql`
@endtask

@task('status')
    cd "{{ $path }}"
    git status
    echo "=========="
    git log -1 --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
@endtask
