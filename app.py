from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import text
import time, datetime

app = Flask(__name__)
# Update the below configuration with your existing PostgreSQL database details
psql_user = 'postgres'
psql_password = ''
db_name = 'pits'
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://{}:{}@localhost/{}'.format(psql_user, psql_password, db_name)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

@app.route('/')
def index():
    # Execute a raw SQL query directly
    connection = db.engine.raw_connection()
    cursor = connection.cursor()
    cursor.execute("SELECT * FROM Stock WHERE sym = 'AAPL';")
    query_result = cursor.fetchall()
    if len(query_result) > 0:
        res = query_result[0]
    else:
        res = []
    return jsonify(res)

# @app.route('/')
# def index():
#     """
#         an alternative implementation of the index() function
#         with query parameter and placeholder
#     """
#     res = []
#     with db.engine.begin() as conn:
#         query_result = conn.execute(text("SELECT * FROM Stock WHERE sym = :sym ;"), 
#                                     dict(sym='AAPL'))
#         for sym, price in query_result:
#             res.append([sym, price])
#     return jsonify(res[0])

@app.route('/getOwner')
def getOwner():
    """
        This HTTP method takes aid as input, and returns all owner's pid in a list
        If the account does not exist, return [{'pid': -1}]
    """
    aid = int(request.args.get('aid', -1))
    # complete the function by replacing the line below with your code
    with db.engine.begin() as conn:
        result = conn.execute(text("SELECT pid FROM Owns WHERE aid = :aid;"), {'aid':aid}).fetchall()
        if result:
            res = [{'pid': row[0]} for row in result]
        else:
            res = [{'pid': -1}]
    return jsonify(res)

@app.route('/getHoldings')
def getHoldings():
    aid = int(request.args.get('aid', -1))
    sym = request.args.get('sym', '')
    
    # complete the function by replacing the line below with your code
    with db.engine.begin() as conn:
        # Check if the account exists
        check_account = conn.execute(text("SELECT 1 FROM Account WHERE aid = :aid"), {'aid': aid}).fetchone()
        # Check if the stock symbol exists
        check_stock = conn.execute(text("SELECT 1 FROM Stock WHERE sym = :sym"), {'sym': sym}).fetchone()

        if not check_account or not check_stock:
            return jsonify({'shares': -1})

        result = conn.execute(text("""
            SELECT COALESCE(SUM(
                CASE 
                    WHEN type = 'buy' THEN shares
                    WHEN type = 'sell' THEN -shares
                END
            ), 0) FROM Trade
            WHERE aid = :aid AND sym = :sym
        """), {'aid': aid, 'sym': sym}).fetchone()

        return jsonify({'shares': float(result[0])})

def currentTime():
    ts = time.time()
    return datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
    
@app.route('/trade')
def trade():
    aid = int(request.args.get('aid', -1))
    sym = request.args.get('sym', '')
    type = request.args.get('type', '')
    shares = float(request.args.get('shares', -1))
    price = float(request.args.get('price', -1))

    if type not in ['buy','sell'] or shares <= 0 or price <= 0:
        return jsonify({'res': 'fail'})

    try:
        with db.engine.begin() as conn:
            #check aid and sym exist 
            account = conn.execute(text("SELECT 1 FROM account WHERE aid = :aid"), {'aid': aid}).fetchone()    
            stock = conn.execute(text("SELECT 1 FROM stock WHERE sym = :sym"),{'sym': sym}).fetchone()

            if not account or not stock or type not in ['buy','sell'] or shares <= 0 or price <= 0:
                return jsonify({'res': 'fail'})
                
            #check oversell
            if type == 'sell':
                result = conn.execute(text("""
                    SELECT type, shares FROM trade 
                    WHERE aid = :aid AND sym = :sym
                    """), {'aid': aid, 'sym': sym}).fetchall()
                held = 0
                for t,s in result:
                   held += s if t == 'buy' else -s
                if shares > held:
                   return jsonify({'res': 'fail'})
                
            #get max seq
            seq_row = conn.execute(text('SELECT MAX(seq) FROM trade WHERE aid = :aid'), {'aid': aid}).fetchone()
            next_seq = (seq_row[0] or 0) + 1

            
            timestamp = currentTime()
            conn.execute(text("""
                INSERT INTO trade(aid, seq, type, timestamp, sym, shares, price)
                VALUES (:aid, :seq, :type, :timestamp, :sym, :shares, :price)
            """), {
                'aid': aid,
                'seq': next_seq,
                'type': type,
                'timestamp': timestamp,
                'sym': sym,
                'shares': shares,
                'price': price
            })
            return jsonify({'res': next_seq})
    except Exception as e:
        return jsonify({'res': 'fail'})

    # complete the function by replacing the line below with your code
    

if __name__ == '__main__':
    app.run(host="0.0.0.0", debug=True, port=5000)