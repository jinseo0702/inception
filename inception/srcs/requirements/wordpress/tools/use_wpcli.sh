#!/bin/sh


IMAGE_WP_SOURCE_PATH="/var/wordpress"
VOLUME_WP_TARGET_PATH="/var/www/html/wordpress"
MARIADB_PASSWORD=$(cat /run/secrets/db_password)
flag=0
if [ ! -f "${VOLUME_WP_TARGET_PATH}/wp-load.php" ]; then

  flag=1
  echo "WordPress not found in volume (${VOLUME_WP_TARGET_PATH})."
  echo "Copying WordPress files from image source (${IMAGE_WP_SOURCE_PATH}) to volume..."
  mkdir -p "${VOLUME_WP_TARGET_PATH}"
  cp -a ${IMAGE_WP_SOURCE_PATH}/. ${VOLUME_WP_TARGET_PATH}/ # 여기서 이미지 안의 파일을 볼륨으로 복사
  rm -rf ${IMAGE_WP_SOURCE_PATH}
  echo "WordPress files copied from image to volume."

key=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

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

else
  echo "WordPress files already exist in volume (${VOLUME_WP_TARGET_PATH})."
fi
sed -i 's/listen = 127.0.0.1:9000/listen = 0.0.0.0:9000/g' ./etc/php82/php-fpm.d/www.conf

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

echo "waiting reset db"
sleep 30
echo "fin reset db"

if [ $flag -eq 1 ]; then
wp core install --url=https://localhost:443 --title="inception" --admin_user="${WORDPRESS_SUPER_USER}" --admin_password="${MARIADB_PASSWORD}" --admin_email="${WORDPRESS_SUPER_USER_EMAIL}" --allow-root --path=/var/www/html/wordpress 

wp language core install ko_KR --path=/var/www/html/wordpress --allow-root
wp language core activate ko_KR --path=/var/www/html/wordpress --allow-root

wp user create jinseo jinseo@wordpress.co.kr --role=subscriber --user_pass=a123456789 --path=/var/www/html/wordpress

echo "
	define('WP_HOME', 'https://' . $_SERVER['HTTP_HOST']);
	define('WP_SITEURL', 'https://' . $_SERVER['HTTP_HOST']);
" >> /var/www/html/wordpress/wp-config.php

fi

chown -R nobody:nobody /var/www/html && \
chmod 777 /var/www/html/ && \
find /var/www/html -type f -exec chmod 777 {} \;
find /var/www/html -type d -exec chmod 777 {} \;

echo Hello World

exec php-fpm82 --nodaemonize
