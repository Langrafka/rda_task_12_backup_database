#!/bin/bash
set -euo pipefail

if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "Error: DB_USER and DB_PASSWORD must be set"
  exit 1
fi

# 1. Створення повного бекапу для ShopDB і відновлення до ShopDBReserve
echo "Створення повного бекапу для $PROD_DB і відновлення до $RESERVE_DB..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$PROD_DB" > /tmp/backup_full.sql
mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS $RESERVE_DB;"
mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "CREATE DATABASE $RESERVE_DB;"
mysql -u "$DB_USER" -p"$DB_PASSWORD" "$RESERVE_DB" < /tmp/backup_full.sql

# 2. Створення бекапу тільки даних
echo "Перенесення даних з $PROD_DB до $DEV_DB..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" "$PROD_DB" --no-create-info Products > /tmp/backup_data.sql

# Перевірка, чи існує таблиця Products в ShopDBDevelopment
mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "USE $DEV_DB; SHOW TABLES LIKE 'Products';"
if [[ $? -ne 0 ]]; then
  echo "Таблиця Products не знайдена в $DEV_DB"
  exit 1
fi

# Відновлення даних до ShopDBDevelopment
mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DEV_DB" < /tmp/backup_data.sql

# 3. Очищення тимчасових файлів
trap 'rm -f /tmp/backup_full.sql /tmp/backup_data.sql' EXIT

# Перевірка кількості рядків
PRODUCT_COUNT=$(mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM Products;" "$PROD_DB")
RESERVE_COUNT=$(mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM Products;" "$RESERVE_DB")
DEV_COUNT=$(mysql -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT COUNT(*) FROM Products;" "$DEV_DB")

if [[ "$PRODUCT_COUNT" -ne "$RESERVE_COUNT" || "$PRODUCT_COUNT" -ne "$DEV_COUNT" ]]; then
  echo "Перевірка кількості рядків не пройдена! Дані не були коректно відновлені."
  exit 1
fi

echo "Процес резервного копіювання та відновлення завершено!"
