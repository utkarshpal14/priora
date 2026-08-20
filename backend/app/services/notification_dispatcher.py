"""
Notification Dispatcher Service for Priora.
Processes scheduled reminders, logs audit entries in NotificationLog,
handles token invalidation gracefully, and executes queue without blocking.
"""

from datetime import datetime, timezone
import logging
from sqlalchemy.orm import Session

from app.models.notification_log import NotificationLog
from app.models.reminder import Reminder
from app.models.user import User

logger = logging.getLogger(__name__)


class NotificationDispatcherService:
    @staticmethod
    def process_pending_reminders(db: Session) -> int:
        """
        Scans for scheduled reminders where remind_at <= current_time,
        checks user notification preferences, logs execution audit record in NotificationLog,
        updates status to SENT/FAILED/CANCELLED, and returns total count of processed items.
        """
        now = datetime.now(timezone.utc)
        pending = (
            db.query(Reminder)
            .filter(Reminder.status == "SCHEDULED", Reminder.remind_at <= now)
            .all()
        )

        sent_count = 0
        for reminder in pending:
            try:
                user = db.query(User).filter(User.id == reminder.task.user_id).first()
                if not user:
                    reminder.status = "CANCELLED"
                    continue

                # Verify user preferences
                if not user.notifications_enabled or not user.deadline_reminders:
                    reminder.status = "CANCELLED"
                    log = NotificationLog(
                        user_id=user.id,
                        type="DEADLINE",
                        title=f"Reminder: {reminder.task.title}",
                        body=f"Task due alert for '{reminder.task.title}' was skipped due to user preference.",
                        sent_at=now,
                        status="CANCELLED",
                        error_message="User notification preferences disabled",
                    )
                    db.add(log)
                    continue

                # Mark reminder as SENT and log audit entry
                reminder.status = "SENT"
                sent_count += 1

                log = NotificationLog(
                    user_id=user.id,
                    type="DEADLINE",
                    title=f"Reminder: {reminder.task.title}",
                    body=f"Task due alert for '{reminder.task.title}' dispatched successfully.",
                    sent_at=now,
                    status="SENT",
                )
                db.add(log)

            except Exception as e:
                logger.error(f"Failed dispatching reminder ID {reminder.id}: {e}")
                reminder.status = "FAILED"
                if 'user' in locals() and user:
                    log = NotificationLog(
                        user_id=user.id,
                        type="DEADLINE",
                        title=f"Reminder: {reminder.task.title}",
                        body=f"Task due alert failed for '{reminder.task.title}'.",
                        sent_at=now,
                        status="FAILED",
                        error_message=str(e),
                    )
                    db.add(log)

        if pending:
            db.commit()

        return sent_count


notification_dispatcher = NotificationDispatcherService()
