#!/bin/bash

# Перевірка наявності змінних середовища DB_USER та DB_PASSWORD
if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
    echo "DB_USER і DB_PASSWORD повинні бути визначені!"
    exit 1
fi

# Визначення баз даних
PROD_DB="ShopDB"
RESERVE_DB="ShopDBReserve"
DEV_DB="ShopDBDevelopment"

# 1. Створення повного бекапу для ShopDB і відновлення до ShopDBReserve
echo "Створення повного бекапу для $PROD_DB і відновлення до $RESERVE_DB..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" --databases "$PROD_DB" --result-file=/tmp/backup_full.sql

# Перевірка чи створено бекап
if [ $? -eq 0 ]; then
    echo "Повний бекап успішно створений."
else
    echo "Помилка під час створення бекапу."
    exit 1
fi

# Відновлення бекапу до ShopDBReserve
mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS $RESERVE_DB;"
mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE $RESERVE_DB;"
mysql -u "$DB_USER" -p"$DB_PASSWORD" "$RESERVE_DB" < /tmp/backup_full.sql

# Перевірка чи відновлено базу даних
if [ $? -eq 0 ]; then
    echo "Відновлення в $RESERVE_DB успішне."
else
    echo "Помилка під час відновлення $RESERVE_DB."
    exit 1
fi

# 2. Створення бекапу даних для ShopDB і відновлення даних до ShopDBDevelopment
echo "Перенесення даних з $PROD_DB до $DEV_DB..."

# Створення бекапу тільки даних
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" --no-create-info --tables "$PROD_DB" Products > /tmp/backup_data.sql

# Відновлення даних до ShopDBDevelopment
mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DEV_DB" < /tmp/backup_data.sql

# Перевірка чи відновлені дані в ShopDBDevelopment
if [ $? -eq 0 ]; then
    echo "Дані успішно перенесено до $DEV_DB."
else
    echo "Помилка під час перенесення даних до $DEV_DB."
    exit 1
fi

# Очищення тимчасових файлів
rm /tmp/backup_full.sql
rm /tmp/backup_data.sql

echo "Процес резервного копіювання та відновлення завершено!"
