# Priora v1.0.0 — Known Limitations & Operational Considerations

> **Version:** v1.0.0 (Build 100 / RC1 Approved)  
> **Status:** Active  

---

## 1. Local Notification Scope (No Cloud Push / FCM in v1.0.0)

- **Description:** Reminders and deadline notifications are scheduled locally on the device using `flutter_local_notifications` and exact alarm timers.
- **Operational Consideration:** Notifications will trigger reliably on the scheduling device, but reminders do not currently sync across multiple physical devices via cloud push.
- **Future Resolution:** Firebase Cloud Messaging (FCM) push notification infrastructure is planned for v2.0.

---

## 2. Android Battery Optimization Exemption (`UX-003`)

- **Description:** On aggressive Android vendor OS distributions (e.g. Xiaomi MIUI/HyperOS, Samsung One UI, Oppo ColorOS), background apps may be put to sleep if battery optimization is enabled.
- **Operational Consideration:** For guaranteed 100% exact minute reminder delivery, users must tap **"Battery Prompt"** in Priora Settings and choose **ALLOW / Unrestricted**.
- **Mitigation:** UX-003 System Health diagnostics detects battery optimization status live and provides one-tap deep links.

---

## 3. Single-User Device Scope

- **Description:** Priora v1.0.0 is optimized for individual productivity.
- **Operational Consideration:** Shared team workspaces, multi-user task assignment, and real-time collaborative editing are deferred to post-v1.0.0 releases.
