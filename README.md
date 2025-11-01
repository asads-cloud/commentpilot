# 📨 CommentPilot

**AWS-native, serverless smart inbox for Instagram & TikTok DMs.**  
Built as a full-stack MVP to showcase end-to-end cloud engineering, AI integration, and scalable SaaS design.

---

## 🚀 Overview

CommentPilot is a **smart inbox** that unifies **Instagram and TikTok DMs** into a single dashboard; intelligently prioritised, tagged, and summarized for creators and agencies.

This project demonstrates how to design, deploy, and scale a **multi-tenant SaaS** entirely on AWS using serverless architecture, real-time message ingestion, and AI-powered classification.

---

## 💡 MVP Scope — “CommentPilot DMs Edition”

**Tagline:**  
> “One inbox for your Instagram and TikTok DMs; prioritised by importance.”

### 🎯 Goal
Provide creators & agencies with a simple, powerful web dashboard that:
1. Fetches all DMs from Instagram & TikTok (latest → oldest)  
2. Tags messages by intent (fan, lead, support, spam) using AI  
3. Allows direct replies where API permits  
4. Sends daily digests of unread or high-value messages  

---

## 🧩 Why This Focus Works

- **DMs > Comments** for MVP; they contain real business value (brand deals, customers, fans).  
- Private, higher-value interactions → faster monetisation.  
- Few tools handle both **IG + TikTok DMs** well.  
- Serverless design = faster launch, lower costs, and easier scale.

---

## ⚙️ Feature Breakdown (v1 Launch)

| Feature | AWS Components | Description |
|----------|----------------|-------------|
| Auth + Accounts | Cognito | Multi-tenant user auth (social sign-in optional) |
| Integrations | Lambda | Connect Instagram + TikTok via OAuth |
| Message Fetching | Lambda + S3 | Pull new DMs, store raw payloads |
| Data Cleaning | Glue | Normalize, deduplicate, prepare for analytics |
| Storage | DynamoDB | Store message data with tags + sentiment |
| AI Classification | Comprehend | Detect tone and categorize messages |
| Dashboard UI | Amplify / Next.js | Unified inbox, filters, and search |
| Alerts / Digest | SES + EventBridge | Send daily digests or Slack alerts |
| Billing | Stripe | Subscription tiers for users and agencies |

---

## 🛠️ Expansion Roadmap (Future-Proof)

| Phase | Additions | Tech Impact |
|--------|------------|-------------|
| v1 | Instagram + TikTok DMs | Core ETL + UI |
| v2 | Comment ingestion (IG, TikTok, YT) | Extend Glue schema |
| v3 | Slack/Discord integrations | Add connectors |
| v4 | Advanced AI (lead detection, sentiment heatmaps) | Custom Comprehend models |
| v5 | Team collaboration | Roles, shared inbox |
| v6 | SaaS API | Let agencies integrate directly |

---

## 🧠 Why This Project Matters

| Reason | Benefit |
|---------|----------|
| **AWS-native everything** | Showcases Glue, Lambda, Comprehend, DynamoDB, EventBridge |
| **Scalable + cost-efficient** | 100% serverless — pay only per message |
| **Demonstrates SaaS design** | Auth, billing, multi-tenancy, analytics, automation |
| **Visually impressive** | Real-time dashboard with live sentiment |
| **Easy to extend** | Plug-and-play for future platforms |

---

## 🏗️ Architecture Highlights

**Pattern:** Event-driven, fully serverless  
**Core AWS stack:**  
- **Lambda** — microservices for ingestion & processing  
- **Glue + DynamoDB** — ETL & data persistence  
- **Comprehend** — NLP for sentiment and intent  
- **EventBridge + SES** — automated digests & alerts  
- **Amplify / Next.js** — frontend hosting + auth integration  
- **Stripe + Cognito** — billing and user management  

---

## 🧰 Built With

- **AWS Glue, Lambda, DynamoDB, EventBridge, Comprehend**
- **Next.js / Amplify**
- **Stripe Billing**
- **OAuth Integrations (Instagram / TikTok)**

---

## 🌍 Designed To Impress

This project demonstrates:
- Real-world **data pipelines** with AWS Glue ETL  
- **Multi-tenant architecture** for SaaS scalability  
- **AI-powered message intelligence**  
- A **production-grade serverless stack** suitable for any B2B SaaS  

---

## 🧾 License

MIT License. See [LICENSE](./LICENSE) for details.
