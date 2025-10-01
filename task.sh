#!/bin/bash

# Зупинка скрипту, якщо виникає будь-яка помилка
set -e

# Перевірка чи задані змінні середовища для користувача та пароля
if [[ -z "$DB_USER" || -z "$DB_PASSWORD" ]]; then
  echo "Error: DB_USER and DB_PASSWORD must be set"
  exit 1
fi

# 1. Створення повного бекапу для ShopDB і відновлення до ShopDBReserve
echo "Створення повного бекапу для ShopDB і відновлення до ShopDBReserve..."
mysqldump -u"$DB_USER" -p"$DB_PASSWORD" ShopDB > full_backup.sql
mysql -u"$DB_USER" -p"$DB_PASSWORD" ShopDBReserve < full_backup.sql

# 2. Створення бекапу даних для ShopDB і відновлення даних до ShopDBDevelopment
echo "Створення бекапу даних для ShopDB і відновлення до ShopDBDevelopment..."
mysqldump -u"$DB_USER" -p"$DB_PASSWORD" --no-create-info ShopDB > no_schema_backup.sql
mysql -u"$DB_USER" -p"$DB_PASSWORD" ShopDBDevelopment < no_schema_backup.sql

# Очищення тимчасових файлів
rm full_backup.sql no_schema_backup.sql

echo "Резервне копіювання та відновлення завершено!"
