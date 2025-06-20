#!/bin/bash

# Конфигурация
USER=$(whoami)
BACKUP_SERVER="sergey@192.168.100.204"
REMOTE_BACKUP_DIR="/home/sergey/backup/$USER"
RESTORE_DIR="/home/$USER/restored"  # Директория для восстановления

# Получаем список резервных копий
echo "Доступные резервные копии:"
BACKUPS=$(ssh "$BACKUP_SERVER" "ls -d '$REMOTE_BACKUP_DIR'/*/ 2>/dev/null | sort -r")
select BACKUP in $BACKUPS; do
    [ -n "$BACKUP" ] && break
    echo "Неверный выбор, попробуйте снова"
done

# Подтверждение
echo -n "Восстановить $BACKUP в $RESTORE_DIR? (y/N) "
read CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && exit 0

# Очистка
echo "Очищаем целевую директорию..."
rm -rf "$RESTORE_DIR" 2>/dev/null
mkdir -p "$RESTORE_DIR"

# Восстановление
mkdir -p "$RESTORE_DIR"
rsync -az --delete \
      "$BACKUP_SERVER:$BACKUP/" \
      "$RESTORE_DIR/"

echo "Восстановление завершено в $RESTORE_DIR"
