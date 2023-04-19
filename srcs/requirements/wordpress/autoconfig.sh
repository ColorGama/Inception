#!/bin/bash
chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress

sed -i '/^\[www\]$/a clear_env = no' /etc/php/7.3/fpm/pool.d/www.conf
sed -i 's/^listen = .*/listen = wordpress:9000/' /etc/php/7.3/fpm/pool.d/www.conf

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
chown -R $USER:$USER wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

while ! mariadb -h$HOST -u$USER -p$U_PWD $DATABASE &>/dev/null; do
    sleep 3
done
if [ ! -f /var/www/wordpress/wp-config.php ]; then

    cd /var/www/wordpress
    sudo -u $USER wp core download
    sudo -u $USER wp config create \
        --dbname=$DATABASE \
        --dbuser=$USER \
        --dbpass=$U_PWD \
	    --dbhost=$HOST --path='/var/www/wordpress'
    sudo -u $USER  wp core install --url='https://127.0.0.1' --title='Inception' --admin_user='ecolin' --admin_password=$ADMIN_PWD --admin_email=$ADMIN_EMAIL
    sudo -u $USER wp user create $USER_WP $USER_EMAIL --role=author --user_pass=$USER_PWD
    sudo -u $USER wp option update comment_status open
    sudo -u $USER wp option set default_comment_status moderated
fi
mkdir /run/php
chown www-data:www-data /run/php/

/usr/sbin/php-fpm7.3 -F