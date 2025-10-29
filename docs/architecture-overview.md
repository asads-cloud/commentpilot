# CommentPilot — Architecture Overview (Phase 0)

**Region:** \eu-west-1\  
**Global prefix:** \commentpilot\

This document tracks the MVP architecture at a high level. In Phase 0 we only stand up the
Terraform backend. Later phases will add Cognito, API Gateway + Lambda, S3 data lake,
Glue ETL, DynamoDB, Comprehend enrichment, EventBridge scheduling, and alerting via SNS/SES/Slack.

## High-Level Components (MVP trajectory)

- **Auth:** Cognito (Hosted UI / PKCE)
- **API:** API Gateway → Lambda (handlers)
- **Data Lake:** S3 \raw + \processed
- **ETL:** Glue Jobs (normalize → DynamoDB)
- **NLP:** Comprehend (sentiment) + rule-based intent
- **Storage:** DynamoDB (messages, tenants)
- **Scheduling:** EventBridge
- **Alerts:** SNS → SES + Slack webhooks
- **Frontend:** Next.js (Amplify or S3+CloudFront)
- **Observability:** CloudWatch Logs/Alarms, X-Ray

## Diagram (Mermaid)

`mermaid
flowchart LR
    subgraph Client["Frontend (Next.js)"]
      U[User]
    end

    subgraph Auth["Cognito"]
      Cg[(User Pool)]
    end

    subgraph API["API Layer"]
      APIGW[API Gateway]
      L1[(Lambda: REST handlers)]
    end

    subgraph DataLake["S3 Buckets"]
      S3R[(raw/instagram, raw/tiktok)]
      S3P[(processed/)]
    end

    subgraph ETL["ETL & Enrichment"]
      Glue[Glue Job(s)]
      Comp[Comprehend]
      Rules[Intent Rules]
    end

    subgraph Storage["Data Stores"]
      Dyn[Dyn. Tables: messages, tenants]
    end

    subgraph Sched["Scheduling & Alerts"]
      EVB[EventBridge]
      SNS[SNS]
      SES[SES]
      Slack[Slack Webhook]
    end

    subgraph CDN["Static Hosting"]
      CF[CloudFront]
      S3Web[(S3 Website/Amplify)]
    end

    U -->|PKCE| Cg
    U -->|HTTPS| CF --> S3Web
    U -->|HTTPS| APIGW --> L1
    EVB --> L1
    L1 --> S3R
    Glue --> S3P
    Glue --> Dyn
    L1 -->|invoke| Comp --> L1
    L1 --> Rules --> Dyn
    L1 --> SNS --> SES
    SNS --> Slack

Terraform Backend (Phase 0)
S3 bucket: commentpilot-tfstate (versioned, SSE, public access blocked)

DynamoDB table: commentpilot-tflock (key: LockID)

State key: envs/dev/terraform.tfstate
