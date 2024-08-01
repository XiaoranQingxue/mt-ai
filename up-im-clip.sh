#!/bin/bash
# 检查是否提供了容器名称和 API URL
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <docker-container-name> <api-url-ip-and-port>"
  exit 1
fi

VEC_LEN=${3:-640}
CONTAINER_NAME=$1
API_URL_IP_PORT=$2

# 创建一个临时的 Python 脚本文件
PYTHON_SCRIPT=$(mktemp update_vectors.XXXXXX.py)

# 将 Python 代码写入临时文件
cat << EOF > $PYTHON_SCRIPT
import psycopg2
import logging
import sys
import requests
import json

# 数据库连接信息
DB_NAME = "postgres"
DB_USER = "postgres"

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
console_handler.setFormatter(formatter)
logger.addHandler(console_handler)

# API 信息
API_URL = "http://$API_URL_IP_PORT/clip/txt"
API_KEY = "unused"

def get_new_vec(text):
    headers = {'Content-Type': 'application/json', 'api-key': API_KEY}
    body = {'text': text}
    response = requests.post(API_URL, headers=headers, data=json.dumps(body))
    return list(map(float, response.json()['result']))

# 连接到 PostgreSQL 数据库（不使用密码）
conn = psycopg2.connect(dbname=DB_NAME, user=DB_USER)
cur = conn.cursor()

def check_and_update_vec(table_name):
    cur.execute(f"SELECT id, vec FROM {table_name}")
    rows = cur.fetchall()
    if len(rows)>0:
        vec = json.loads(rows[0][1])
        if len(vec) == $VEC_LEN:
            logger.info(f'{table_name} vec长度正常')
            return
    cur.execute(f"ALTER TABLE {table_name} ADD COLUMN new_vec vector($VEC_LEN)")
    for row_id, vec in rows:
        vec = json.loads(vec)
        vec = (vec + [0] * $VEC_LEN)[:$VEC_LEN]
        cur.execute(f"UPDATE {table_name} SET new_vec = %s WHERE id = %s", (vec, row_id))
    cur.execute(f"ALTER TABLE {table_name} DROP COLUMN vec;")
    cur.execute(f"ALTER TABLE {table_name} RENAME COLUMN new_vec TO vec;")
    conn.commit()
    logger.info(f'{table_name} vec成功修改为$VEC_LEN')

def update_table_with_new_vec(table_name):
    cur.execute(f"SELECT id, text FROM {table_name}")
    rows = cur.fetchall()
    for row_id, text in rows:
        new_vec = get_new_vec(text)
        cur.execute(f"UPDATE {table_name} SET vec = %s WHERE id = %s", (new_vec, row_id))
    logger.info(f'{table_name} clip更新完成')

check_and_update_vec('text_clip')
check_and_update_vec('file_clip')
update_table_with_new_vec('text_clip')

conn.commit()
cur.close()
conn.close()
EOF

docker cp $PYTHON_SCRIPT $CONTAINER_NAME:/tmp

# 进入 Docker 容器并执行命令
docker exec -i $CONTAINER_NAME sh -c "
pip install psycopg2-binary requests &&
python3 -u /tmp/$PYTHON_SCRIPT && rm /tmp/$PYTHON_SCRIPT
"

# 删除临时的 Python 脚本文件
rm $PYTHON_SCRIPT
