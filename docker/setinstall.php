<?php

define('WP_INSTALLING', true);
require_once '/var/www/html/wordpress/wp-load.php';
require_once '/var/www/html/wordpress/wp-admin/includes/upgrade.php';
require_once '/var/www/html/wordpress/wp-admin/includes/admin.php';
require_once '/var/www/html/wordpress/wp-admin/includes/translation-install.php';

$blog_title = "$WORDPRESS_TITLE";
$super = "$WORDPRESS_SUPER_USER";
$super_pw = "$MARIADB_PASSWORD";
$super_email = "$WORDPRESS_SUPER_USER_EMAIL";
$public = 1;

$re = wp_install($blog_title, $super, $super_email, $public, '', $super_pw, 'ko_KR');

if ($re) {
    echo "good install \n";
}
else{
    echo "fail install \n";
}

$re2 = wp_download_language_pack( 'ko_KR' );
if ($re2) {
    echo "good install languege\n";
}
else{
    echo "fail install languege\n";
}


$user = "$WORDPRESS_USER";
$user_pw = "$MARIADB_PASSWORD";
$user_email = "$WORDPRESS_USER_EMAIL";
$normaluser = wp_create_user($user, $user_pw, $user_email);
if (!is_wp_error($normaluser)){
    $user = new WP_User($normaluser);
    $user->set_role('subscriber');
	echo "make normal user\n";
}

?>