#!/bin/sh

IMAGE_WP_SOURCE_PATH="/var/wordpress" # Dockerfile에서 만든 이 경로를 사용합니다.
VOLUME_WP_TARGET_PATH="/var/www/html/wordpress"  # 볼륨 마운트 경로

if [ ! -f "${VOLUME_WP_TARGET_PATH}/wp-load.php" ]; then
  echo "WordPress not found in volume (${VOLUME_WP_TARGET_PATH})."
  echo "Copying WordPress files from image source (${IMAGE_WP_SOURCE_PATH}) to volume..."
  mkdir -p "${VOLUME_WP_TARGET_PATH}"
  cp -a ${IMAGE_WP_SOURCE_PATH}/. ${VOLUME_WP_TARGET_PATH}/ # 여기서 이미지 안의 파일을 볼륨으로 복사
  echo "WordPress files copied from image to volume."
else
  echo "WordPress files already exist in volume (${VOLUME_WP_TARGET_PATH})."
fi



key=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
MARIADB_PASSWORD=$(cat /run/secrets/db_password)

cat  > /var/www/html/wordpress/wp-config.php <<eof

<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the website, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
	 *
	 * * Database settings
	 * * Secret keys
	 * * Database table prefix
	 * * ABSPATH
	 *
	 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/
	 *
	 * @package WordPress
	 */
	
	// ** Database settings - You can get this info from your web host ** //
	/** The name of the database for WordPress */
	define( 'DB_NAME', '${MARIADB_DATABASE}' );
	
	/** Database username */
	define( 'DB_USER', '${MARIADB_MYSQL_LOCALHOST_USER}' );
	
	/** Database password */
	define( 'DB_PASSWORD', '${MARIADB_PASSWORD}' );
	
	/** Database hostname */
	define( 'DB_HOST', '${DB_HOST}' );
	
	/** Database charset to use in creating database tables. */
	define( 'DB_CHARSET', 'utf8' );
	
	/** The database collate type. Don't change this if in doubt. */
	define( 'DB_COLLATE', '' );
	
	/**#@+
	 * Authentication unique keys and salts.
	 *
	 * Change these to different unique phrases! You can generate these using
	 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
	 *
	 * You can change these at any point in time to invalidate all existing cookies.
	 * This will force all users to have to log in again.
	 *
	 * @since 2.6.0
	 */
${key}
	
	/**#@-*/
	
	/**
	 * WordPress database table prefix.
	 *
	 * You can have multiple installations in one database if you give each
	 * a unique prefix. Only numbers, letters, and underscores please!
	 *
	 * At the installation time, database tables are created with the specified prefix.
	 * Changing this value after WordPress is installed will make your site think
	 * it has not been installed.
	 *
	 * @link https://developer.wordpress.org/advanced-administration/wordpress/wp-config/#table-prefix
	 */
	\$table_prefix = 'wp_';
	
	/**
	 * For developers: WordPress debugging mode.
	 *
	 * Change this to true to enable the display of notices during development.
	 * It is strongly recommended that plugin and theme developers use WP_DEBUG
	 * in their development environments.
	 *
	 * For information on other constants that can be used for debugging,
	 * visit the documentation.
	 *
	 * @link https://developer.wordpress.org/advanced-administration/debug/debug-wordpress/
	 */
	define( 'WP_DEBUG', true );
	define( 'WP_DEBUG_LOG', true ); // 오류를 /wp-content/debug.log 파일에 기록
	define( 'WP_DEBUG_DISPLAY', false ); // 브라우저에 오류를 표시하지 않음 (보안상 권장)
	@ini_set( 'display_errors', 0 ); // 브라우저에 오류를 표시하지 않도록 강제
	
	/* Add any custom values between this line and the "stop editing" line. */
	
	
	
	/* That's all, stop editing! Happy publishing. */
	
	/*
	\$mysqli_test = mysqli_init();
	if (!\$mysqli_test) {
	    die('mysqli_init failed during wp-config test');
	}
	\$test_host = 'db';
	\$test_user = 'wordpress';
	\$test_password = 'a123456789';
	\$test_database = 'wordpress';
	\$test_conn_result = mysqli_real_connect(\$mysqli_test, \$test_host, \$test_user, \$test_password, \$test_database);

	if (\$test_conn_result) {
	    mysqli_close(\$mysqli_test);
	} else {
	    die('Direct mysqli connect in wp-config.php: FAIL - ' . mysqli_connect_error());
	}
	*/

	define( 'WPLANG', 'ko_KR' );

	/** Absolute path to the WordPress directory. */
	if ( ! defined( 'ABSPATH' ) ) {
	        define( 'ABSPATH', __DIR__ . '/' );
	}
	
	/** Sets up WordPress vars and included files. */



	require_once ABSPATH . 'wp-settings.php';
eof

sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/g' ./etc/php82/php-fpm.d/www.conf

cat > /var/www/html/wordpress/create_user.php <<eof

<?php

require_once "/var/www/html/wordpress/wp-load.php";

\$normaluser = wp_create_user("$WORDPRESS_USER", "$MARIADB_PASSWORD", "$WORDPRESS_USER@wordpress");
if (!is_wp_error(\$normaluser)){
    \$user = new WP_User(\$normaluser);
    \$user->set_role('subscriber');
	echo "make normal user\n";
}
else{
	echo "dont make user \n";
}

?>

eof


cat > /var/www/html/wordpress/wp-installing.php <<eof
<?php

define('WP_INSTALLING', true);
require_once '/var/www/html/wordpress/wp-load.php';
require_once '/var/www/html/wordpress/wp-admin/includes/upgrade.php';
require_once '/var/www/html/wordpress/wp-admin/includes/admin.php';
require_once '/var/www/html/wordpress/wp-admin/includes/translation-install.php';

\$blog_title = "$WORDPRESS_TITLE";
\$super = "$WORDPRESS_SUPER_USER";
\$super_pw = "$MARIADB_PASSWORD";
\$super_email = "$WORDPRESS_SUPER_USER_EMAIL";
\$public = 1;

\$re = wp_install(\$blog_title, \$super, \$super_email, \$public, '', \$super_pw, 'ko_KR');

if (\$re) {
    echo "good install \n";
}
else{
    echo "fail install \n";
}

\$re2 = wp_download_language_pack( 'ko_KR' );
if (\$re2) {
    echo "good install languege\n";
}
else{
    echo "fail install languege\n";
}

eof


cat > /var/www/html/wordpress/fix-urls.php <<eof
<?php
require_once '/var/www/html/wordpress/wp-load.php';

// 현재 설정 확인
echo "Current settings:\n";
echo "Site URL: " . get_option('siteurl') . "\n";
echo "Home URL: " . get_option('home') . "\n";

// URL 수정 - 실제 접속 URL로 변경
update_option('siteurl', 'http://localhost:8080');
update_option('home', 'http://localhost:8080');

// 수정 후 설정 확인
echo "\nUpdated settings:\n";
echo "Site URL: " . get_option('siteurl') . "\n";
echo "Home URL: " . get_option('home') . "\n";

// 필요한 경우 퍼머링크 설정 업데이트
update_option('permalink_structure', '/%postname%/');
echo "Permalink structure updated\n";
?>
eof

# URL 수정 스크립트 실행


echo "Hello waiting start"
sleep 20
echo "Hello waiting finish"
php82 /var/www/html/wordpress/wp-installing.php
echo "Hello2 waiting start"
sleep 20
echo "Hello2 waiting finish"
php82 /var/www/html/wordpress/create_user.php
sleep 5
php82 /var/www/html/wordpress/fix-urls.php

chown -R nobody:nobody /var/www/html && \
chmod 755 /var/www/html/ && \
find /var/www/html -type f -exec chmod 644 {} \;

exec php-fpm82 --nodaemonize