#!/bin/bash

echo "🔐 إعداد مهمة تجديد الشهادة التلقائية باستخدام certbot..."

# تأكد من وجود certbot و nginx
if ! command -v certbot &> /dev/null
then
    echo "❌ Certbot مش مثبت. برجاء تثبيته أولاً (مثلاً: sudo apt install certbot python3-certbot-nginx)"
    exit 1
fi

if ! command -v nginx &> /dev/null
then
    echo "❌ Nginx مش مثبت. برجاء تثبيته أولاً."
    exit 1
fi

# إضافة المهمة لـ crontab
CRON_JOB='0 3,15 * * * certbot renew --quiet --post-hook "systemctl reload nginx"'

# التحقق إذا كانت المهمة موجودة بالفعل
( sudo crontab -l | grep -qF "$CRON_JOB" ) && echo "✅ المهمة موجودة بالفعل في crontab." || (
    echo "➕ بيتم إضافة المهمة لـ crontab..."
    (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
    echo "✅ تم إضافة المهمة بنجاح."
)

# تجربة تجديد تجريبي
echo "🧪 بيتم تنفيذ تجربة تجديد جاف..."
sudo certbot renew --dry-run

echo "🎉 تم الإعداد بنجاح."
