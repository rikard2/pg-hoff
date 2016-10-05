from flask import Flask, request, Response
import logging
import sys
import os
import site
import traceback
#import queue
import datetime
from urllib.parse import urlparse
from threading import Lock, Thread
from collections import defaultdict
global PGCli, need_completion_refresh, need_search_path_refresh
global has_meta_cmd, has_change_path_cmd
from pgcli.main import PGCli, has_meta_cmd, has_change_path_cmd
global PGExecute
from pgcli.pgexecute import PGExecute
global PGCompleter
from pgcli.pgcompleter import PGCompleter
global special
from pgspecial import PGSpecial
special = PGSpecial()
global CompletionRefresher
from pgcli.completion_refresher import CompletionRefresher
global Document
from prompt_toolkit.document import Document
global format_output
from pgcli.main import format_output
global psycopg2
import psycopg2
global sqlparse
import sqlparse
import json
import uuid
import datetime
import time

completers = defaultdict(list)  # Dict mapping urls to pgcompleter objects
completer_lock = Lock()

executors = defaultdict(list)  # Dict mapping buffer ids to pgexecutor objects
executor_lock = Lock()

bufferConnections = defaultdict(str) #Dict mapping bufferids to connectionstrings

queryResults = defaultdict(list)

password = None

def new_executor(url, pwd=None):
    global password
    password = None
    uri = urlparse(url)
    database = uri.path[1:]  # ignore the leading fwd slash
    dsn = None  # todo: what is this for again
    return PGExecute(database, uri.username, pwd or uri.password, uri.hostname,
                     uri.port, dsn)

def replace_completer(comp):
    global completer
    completer = comp

refresher = CompletionRefresher()
executor = new_executor('postgresql://vagrant@192.168.13.37/vagrant')
completer = PGCompleter()
refresher.refresh(executor, special=special, callbacks=replace_completer)

def run_sql(sql, uuid):
    for sql in sqlparse.split(sql):
        queryResults[uuid].append({
            'columns': None,
            'rows': None,
            'query': sql,
            'notices': None,
            'complete': False,
            'executing': False,
            'timestamp': None,
            'runtime_seconds': None
        })
    with executor_lock:
        with executor.conn.cursor() as cur:
            for n, qr in enumerate(queryResults[uuid]):
                timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
                timestamp_ts = time.mktime(datetime.datetime.now().timetuple())
                currentQuery = queryResults[uuid][n]
                currentQuery['timestamp'] = time.strftime('%Y-%m-%d %H:%M:%S')
                currentQuery['executing'] = True
                queryResults[uuid][n] = currentQuery
                #start thread for polling notices
                #t = Thread(target=get_notices,
                #               args=(queryResults[uuid][n], executor.conn),
                #               name='get_notices')
                #t.setDaemon(True)
                #t.start()

                #run query
                cur.execute(qr['query'])
                #update query result
                currentQuery['columns'] = [{'name': d.name, 'type_code': d.type_code} for d in cur.description]
                currentQuery['rows'] = [x for x in cur.fetchall()]
                currentQuery['runtime_seconds'] = int(time.mktime(datetime.datetime.now().timetuple())-timestamp_ts)
                currentQuery['complete'] = True
                currentQuery['executing'] = False
                queryResults[uuid][n] = currentQuery

def get_notices(currentQuery, con):
    notices = []
    while True:
        while conn.notices:
            notices.add(executor.conn.notices.pop(0))
        queryResult['notices'] = notices
        time.sleep(1)

app = Flask(__name__)
@app.route("/query", methods=['POST'])
def hello():
    sql = request.form['query']
    uid = str(uuid.uuid1())
    t = Thread(target=run_sql,
                   args=(sql, uid),
                   name='run_sql')
    t.setDaemon(True)
    t.start()
    return 'localhost:5000/result/' + uid

@app.route("/result/<uuid>")
def result(uuid):
    result = queryResults[uuid]
    for r in result:
        if r['executing'] == 1:
            timestamp_ts = time.mktime(datetime.datetime.strptime(r["timestamp"], '%Y-%m-%d %H:%M:%S').timetuple())
            r["runtime_seconds"] = int(time.mktime(datetime.datetime.now().timetuple())-timestamp_ts)
    return Response(str(json.dumps(result)), mimetype='text/json')

@app.route("/pos/<pos>/query/<query>")
def lol(pos,query):
    comps = completer.get_completions(
                Document(text=query, cursor_position=int(pos)), None)
    return 'hej'#Response(str(json.dumps([c.text for c in comps])), mimetype='text/json')


if __name__ == "__main__":
    app.run()
