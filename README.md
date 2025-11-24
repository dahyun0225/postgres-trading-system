# PostgreSQL Trading System – Real-Time Stock Backend (Flask + SQL)

This project implements a simplified real-time stock trading backend system using **PostgreSQL** and **Flask**, designed to mimic core behaviors of real financial trading infrastructures.  
It was built as a full end-to-end backend system that covers **database design, transaction validation, API development, and trading logic enforcement**.

---

## 1. Project Overview

The system provides the essential functionality of a trading service:

- Buy / sell stocks  
- Prevent overselling using transaction-safe checks  
- Retrieve current holdings  
- Retrieve account owner information  
- Log every trade in an append-only ledger

All core logic is implemented at the **database level (PostgreSQL)** to ensure data integrity, reliability, and production-style safety.

---

## 2. System Architecture

### **Backend: Flask API**
The backend exposes three primary endpoints:

| Endpoint | Description |
|---------|-------------|
| `GET /getOwner` | Returns the owner of a given account |
| `GET /getHoldings` | Returns current holdings (real-time calculated) |
| `POST /trade` | Executes a buy or sell transaction |

The API directly interacts with PostgreSQL and performs safe transaction handling.

---

## 3. Database Design (PostgreSQL)

The system uses a relational schema designed for correctness, consistency, and trading safety.

### **Key tables:**
- `Accounts` — account owner information  
- `Brokers` — registered brokers  
- `Trades` — append-only ledger of all executed orders  
- `Holds` — view that calculates current positions in real time  

### **Key constraints implemented**
- Primary/Foreign keys  
- CHECK constraints  
- Prevent broker-owned accounts  
- Prevent negative holdings (oversell prevention)

### **Triggers**
Triggers enforce:
- Append-only logging  
- Trade timestamp ordering  
- Account & broker rule enforcement  
- Data integrity across all tables  

---

## 4. Trading Logic (Core Features)

The trading engine includes:

### Oversell Prevention  
Before executing a SELL order, the system ensures:

- Required quantity exists  
- Transaction is atomic (ACID compliant)  
- Database locks prevent race conditions  

### Append-Only Ledger  
All trades are permanently logged using triggers.

### Real-Time Holdings View  
A `Holds` VIEW computes:
SUM(buys) - SUM(sells)

This allows real-time calculation without duplicating data.

### Error-Proof Transaction Handling  
All operations use PostgreSQL transactions to ensure correctness under concurrent execution.

---

## 5. Files in This Repository

| File | Description |
|------|-------------|
| **app.py** | Flask REST API for trading operations |
| **create.sql** | Full PostgreSQL schema, constraints, views, and triggers |

---

## 6. Tech Stack

- **Flask** – lightweight backend API  
- **PostgreSQL** – storage, triggers, transactions  
- **SQL** – schema design, business logic, data integrity  
- **Docker (optional)** – containerized DB setup  

---

## 7. Why This Project Matters

This system simulates the backend architecture used in:

- Financial trading systems  
- Banking transaction engines  
- Brokerage platforms  
- High-integrity data pipelines  

It demonstrates real-world skills including:

- Database-first system design  
- SQL constraints & trigger development  
- Transaction-safe business logic  
- Production-style API development  

---

## Author

**Dahyeon Choi**  
Aug, 2025

---

# PostgreSQL 기반 실시간 주식 거래 백엔드 시스템 (Flask + SQL)

이 프로젝트는 **PostgreSQL**과 **Flask**를 활용하여  
실제 금융 트레이딩 시스템의 핵심 기능을 단순화해 구현한 **주식 거래 백엔드 시스템**입니다.  

데이터베이스 설계부터 트랜잭션 검증, 거래 규칙 강제, API 개발까지  
엔터프라이즈급 백엔드의 전 과정을 직접 구축한 프로젝트입니다.

---

## 1. 프로젝트 개요

이 시스템은 기본적인 주식 거래 서비스의 필수 기능을 제공합니다:

- 주식 **매수 / 매도**
- **오버셀(초과 매도) 방지**  
- **현재 보유 종목 조회**
- **계좌 소유자 정보 조회**
- **Append-only 형태의 거래 로그 기록**

특히 금융 시스템에서 중요한 **데이터 무결성·일관성·트랜잭션 안정성**을  
PostgreSQL 레이어에서 강력하게 보장하도록 설계되었습니다.

---

## 2. 시스템 아키텍처

### Flask API (백엔드 서버)
다음의 3가지 주요 엔드포인트를 제공합니다:

| 엔드포인트 | 설명 |
|-----------|------|
| `GET /getOwner` | 계좌 소유자 조회 |
| `GET /getHoldings` | 계좌별 보유 주식 실시간 조회 |
| `POST /trade` | 매수/매도 거래 수행 |

Flask 서버는 PostgreSQL과 직접 통신하며 트랜잭션 기반으로 안전하게 주문을 처리합니다.

---

## 3. PostgreSQL 데이터베이스 설계

### 주요 테이블
- `Accounts` — 계좌 및 사용자 정보  
- `Brokers` — 등록된 브로커  
- `Trades` — 모든 거래 기록(append-only)  
- `Holds` — 실시간 포지션 계산 VIEW  

### 핵심 제약조건
- PK/FK  
- CHECK 제약조건  
- 브로커 계좌 금지  
- 음수 보유량 금지 (오버셀 방지)

### 트리거(Trigger)
DB 트리거를 통해 다음을 강제합니다:

- 거래 로그 append-only 보장  
- 거래 시간 순서 강제  
- 계좌/브로커 규칙 검증  
- 데이터 무결성 강화  

---

## 4. 거래 로직 (핵심 구현 포인트)

### 오버셀 방지
SELL 주문 시:

- 보유 수량 검증  
- 트랜잭션 원자성 보장  
- 경쟁 상태(race condition) 방지  

### 거래 내역 Append-only  
모든 주문은 **삭제/수정 불가**, 오직 누적 저장만 가능.

### 실시간 보유량 계산 VIEW  
`Holds` VIEW에서:
SUM(매수) - SUM(매도)

형태로 계산해 고성능 조회 가능.

### 트랜잭션 기반 오류 방지 처리  
PostgreSQL의 트랜잭션을 활용해  
동시 접근 상황에서도 정확한 결과 보장.

---

## 5. 저장소 파일 구조

| 파일 | 설명 |
|------|------|
| **app.py** | Flask 기반 REST API |
| **create.sql** | PostgreSQL 스키마 + 제약조건 + 트리거 + VIEW |

---

## 6. 기술 스택

- **Flask**  
- **PostgreSQL**  
- **SQL (스키마 + 트리거 + 비즈니스 로직)**  
- Docker (선택)

---

## 7. 이 프로젝트의 의의

본 시스템은 다음과 같은 실제 산업 시스템을 축소 구현한 것입니다:

- 금융 트레이딩 엔진  
- 은행 결제/거래 시스템  
- 증권사 백오피스  
- 트랜잭션 안정성이 중요한 모든 시스템  

이를 통해 다음 역량을 입증합니다:

- 데이터베이스 중심 시스템 설계
- SQL 기반 비즈니스 로직 설계
- 오버셀 방지 등 금융 규칙 적용
- 프로덕션 스타일의 API 개발
- 트랜잭션·무결성 보장 시스템 구축 경험

---

## 작성자

**최다현 (Dahyeon Choi)**  
Aug, 2025
