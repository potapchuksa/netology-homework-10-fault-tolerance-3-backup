#!/bin/bash

# Конфигурация
USER=$(whoami)
SOURCE_DIR="/home/$USER"
BACKUP_SERVER="sergey@192.168.100.204"  # Замените на данные вашего сервера
REMOTE_BACKUP_DIR="/home/sergey/backup/$USER"
MAX_BACKUPS=5

# Проверяем доступность сервера
if ! ssh -q "$BACKUP_SERVER" exit; then
    echo "Ошибка: не удалось подключиться к серверу $BACKUP_SERVER"
    exit 1
fi

# Создаём структуру каталогов на сервере
ssh "$BACKUP_SERVER" "mkdir -p '$REMOTE_BACKUP_DIR'"

# Получаем последнюю резервную копию
LATEST=$(ssh "$BACKUP_SERVER" "ls -d '$REMOTE_BACKUP_DIR'/*/ 2>/dev/null | sort -r | head -n 1")

# Создаём новую копию с временной меткой
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
NEW_BACKUP="$REMOTE_BACKUP_DIR/$TIMESTAMP"

# Выполняем инкрементное копирование
if [ -z "$LATEST" ]; then
    echo "Создаём первую полную копию..."
    rsync -az --delete \
          "$SOURCE_DIR/" \
          "$BACKUP_SERVER:$NEW_BACKUP/"
else
    echo "Создаём инкрементную копию на основе $LATEST..."
    rsync -az --delete \
          --link-dest="$LATEST" \
          "$SOURCE_DIR/" \
          "$BACKUP_SERVER:$NEW_BACKUP/"
fi

# Удаляем старые копии
BACKUP_LIST=$(ssh "$BACKUP_SERVER" "ls -d '$REMOTE_BACKUP_DIR'/*/ 2>/dev/null | sort -r")
COUNT=$(echo "$BACKUP_LIST" | wc -l)

if [ "$COUNT" -gt "$MAX_BACKUPS" ]; then
    echo "Удаляем старые копии..."
    OLD_BACKUPS=$(echo "$BACKUP_LIST" | tail -n +$(($MAX_BACKUPS + 1)))
    for OLD in $OLD_BACKUPS; do
        ssh "$BACKUP_SERVER" "rm -rf '$OLD'"
        echo "Удалено: $OLD"
    done
fi

echo "Резервное копирование завершено: $TIMESTAMP"
