import flask
import sqlite3
import json

app = flask.Flask(__name__)
logger = app.logger

def init_db():
    conn = sqlite3.connect('plans.db')
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS plans
                 (id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT)''')
    conn.commit()
    conn.close()

init_db()

@app.route('/hello')
def hello():
    return "Hello, World!"

@app.route('/plans', methods=['GET', 'POST'])
def plans():
    if flask.request.method == 'POST':
        request_data = flask.request.get_json()
        # log the request data for debugging purposes with logger

        logger.info(f"Received request data: {request_data}")
        
        conn = sqlite3.connect('plans.db')
        c = conn.cursor()
        c.execute("INSERT INTO plans (content) VALUES (?)", (json.dumps(request_data),))
        conn.commit()
        conn.close()
        
        return "OK !", 200
    else:
        conn = sqlite3.connect('plans.db')
        c = conn.cursor()
        c.execute("SELECT content FROM plans")
        rows = c.fetchall()
        conn.close()
        
        plans_list = [json.loads(row[0]) for row in rows]
        return flask.jsonify(plans_list)

if __name__ == '__main__':
    app.run(debug=True, port = 8000, host='0.0.0.0')