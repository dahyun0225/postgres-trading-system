----------------------------------------------------------------------
-- enforced by CREATE TABLE statements 

CREATE TABLE Person
(pid DECIMAL(10,0) NOT NULL PRIMARY KEY,
 name VARCHAR(256) NOT NULL,
 address VARCHAR(256) NOT NULL);

CREATE TABLE Broker
(pid DECIMAL(10,0) NOT NULL PRIMARY KEY REFERENCES Person(pid),
 license VARCHAR(20) NOT NULL UNIQUE,
 phone DECIMAL(10,0) NOT NULL,
 manager DECIMAL(10,0) REFERENCES Broker(pid));

CREATE TABLE Account
(aid INTEGER NOT NULL PRIMARY KEY,
 brokerpid DECIMAL(10,0) NOT NULL REFERENCES Broker(pid));

CREATE TABLE Owns
(pid DECIMAL(10,0) NOT NULL REFERENCES Person(pid),
 aid INTEGER NOT NULL REFERENCES Account(aid),
 PRIMARY KEY (pid, aid));

CREATE TABLE Stock
(sym CHAR(5) NOT NULL PRIMARY KEY,
 price DECIMAL(10,2) NOT NULL);

CREATE TABLE Trade
(aid INTEGER NOT NULL REFERENCES Account(aid),
 seq INTEGER NOT NULL,
 type CHAR(4) NOT NULL CHECK(type = 'buy' OR type = 'sell'),
 timestamp TIMESTAMP NOT NULL,
 sym CHAR(5) NOT NULL REFERENCES Stock(sym),
 shares DECIMAL(10,2) NOT NULL,
 price DECIMAL(10,2) NOT NULL,
 PRIMARY KEY (aid, seq));



CREATE FUNCTION TF_TradeSeqAppendOnly() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP IN ('DELETE', 'UPDATE') THEN
    RAISE EXCEPTION 'trade table is append-only';
  END IF;

  IF EXISTS (
    SELECT 1 FROM Trade
    WHERE aid = NEW.aid AND seq >= NEW.seq
  ) THEN 
    RAISE EXCEPTION 'trade seq must be strictly increasing';
    END IF;

  If EXISTS ( 
    SELECT 1 FROM Trade
    WHERE aid = NEW.aid AND timestamp > NEW.timestamp
  ) THEN
    RAISE EXCEPTION 'trade timestamp must not go backwards';
    END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TG_TradeSeqAppendOnly
  BEFORE INSERT OR UPDATE OR DELETE ON Trade
  FOR EACH ROW
  EXECUTE PROCEDURE TF_TradeSeqAppendOnly();

----------------------------------------------------------------------
-- Using triggers, enforce that brokers cannot own accounts,
-- either by themselves or jointly with others.

CREATE FUNCTION TF_BrokerNotAccountOwner() RETURNS TRIGGER AS $$
BEGIN
  -- YOUR IMPLEMENTATION GOES HERE >>>
  IF TG_TABLE_NAME = 'owns' THEN
    IF EXISTS (SELECT 1 FROM Broker WHERE pid = NEW.pid) THEN
        RAISE EXCEPTION 'Broker (pid = %) cannot own accounts', NEW.pid;
    END IF;
    ELSIF TG_TABLE_NAME = 'broker' THEN
    IF EXISTS (SELECT 1 FROM Owns WHERE pid = NEW.pid) THEN
        RAISE EXCEPTION 'A person (pid = %) already owning accounts cannot become a Broker', NEW.pid;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TG_BrokerNotAccountOwner_Broker
  BEFORE INSERT OR UPDATE OF pid ON Broker
  -- DELETE won't cause a violation
  FOR EACH ROW
  EXECUTE PROCEDURE TF_BrokerNotAccountOwner();

CREATE TRIGGER TG_BrokerNotAccountOwner_Owns
  BEFORE INSERT OR UPDATE OF pid ON Owns
  -- DELETE won't cause a violation
  FOR EACH ROW
  EXECUTE PROCEDURE TF_BrokerNotAccountOwner();

----------------------------------------------------------------------
-- Define a view Holds (aid, sym, amount) that returns the current
-- account holdings, computed from the Trade table. may assume
-- that all accounts start with holding nothing and all transactions
-- are recorded in Trade.

CREATE VIEW Holds(aid, sym, shares) AS
  -- Stub implementation (incorrect):
  SELECT  aid, sym,
          SUM(CASE
              WHEN type = 'buy' THEN shares
              WHEN type = 'sell' THEN -shares
              ELSE 0
          END) AS shares
  FROM Trade
  GROUP BY aid, sym;

CREATE FUNCTION TF_NoOverSell() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.type = 'sell' AND
     NEW.shares > COALESCE((SELECT shares FROM Holds WHERE aid = NEW.aid AND sym = NEW.sym), 0) THEN
    RAISE EXCEPTION 'cannot sell more than the number of % shares currently held',
                    NEW.sym;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TG_NoOverSell
  BEFORE INSERT ON Trade
  FOR EACH ROW
  EXECUTE PROCEDURE TF_NoOverSell();
