from flask import Flask, render_template, request, redirect, url_for, session
from pyathena import connect
import pandas as pd
from collections import defaultdict
import os
import requests
from functools import wraps
import boto3

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY', 'lks')
API_GATEWAY_URL = os.environ.get('API_GATEWAY_URL', '')

# Decorator untuk route yang membutuhkan auth
def token_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not session.get('authenticated'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        token = request.form.get('token', '').strip()
        
        if not token:
            return render_template('login.html', error="Token is required")
        
        try:
            response = requests.get(
                f"{API_GATEWAY_URL}/validate-token",
                params={'token': token}
            )
            
            if response.status_code == 200:
                session['authenticated'] = True
                return redirect(url_for('dashboard'))
            else:
                error_msg = response.json().get('error', 'Invalid token')
                return render_template('login.html', error=error_msg)
                
        except requests.RequestException as e:
            return render_template('login.html', error="Service unavailable. Please try later.")
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('authenticated', None)
    return redirect(url_for('login'))

@app.route('/dashboard')
@token_required
def dashboard():
    try:
        sns_client = boto3.client('sns', 
        region_name='us-east-1',
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
        aws_session_token=os.environ.get("AWS_SESSION_TOKEN")
        )
        topic_arn = os.environ.get("SNS_TOPIC_ARN", 'arn:aws:sns:us-east-1:903675765022:techno-sns-payakumbuh-akbar')
        subject = topic_arn.split(':')[-1]
        message = f"Selamat {subject}, You can access your dashboard."

        sns_client.publish(
            TopicArn=topic_arn,
            Message=message,
            Subject='Dashboard Access'
        )
    except Exception as e:
        print(f"Error sending SNS message: {e}")

    
    conn = connect(
        s3_staging_dir=os.environ.get("S3_STAGING_DIR", "s3://technoinput-payakumbuh-akbar"),
        aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
        aws_session_token=os.environ.get("AWS_SESSION_TOKEN"),
        region_name=os.environ.get("AWS_REGION", "us-east-1"),
        schema_name=os.environ.get("ATHENA_SCHEMA_NAME"),
    )

    query = """
        SELECT image_key, label.Name AS label, label.Confidence AS confidence
        FROM rekognition_results_db.rekognition_results_table
        CROSS JOIN UNNEST(labels) AS t(label)
        LIMIT 100
    """

    df = pd.read_sql(query, conn)

    grouped_data = defaultdict(lambda: {'labels': [], 'confidences': [], 'image_url': ''})

    for _, row in df.iterrows():
        image_key = row['image_key']
        if not grouped_data[image_key]['image_url']:
            grouped_data[image_key]['image_url'] = f"https://s3.amazonaws.com/technoinput-payakumbuh-akbar/{image_key}"
        grouped_data[image_key]['labels'].append(row['label'])
        grouped_data[image_key]['confidences'].append(row['confidence'])

    return render_template("index.html", data=grouped_data, zip=zip)


@app.route('/validate-token', methods=['POST'])
def validate_token_api():
    data = request.get_json()
    token = data.get('token', '').strip()

    if not token:
        return {'error': 'Token is required'}, 401

    try:
        response = requests.get(
            f"{API_GATEWAY_URL}/validate-token",
            params={'token': token}
        )

        print("API Response:", response.status_code, response.text)

        if response.status_code == 200:
            session['authenticated'] = True

            # === SNS PUBLISH ===
            try:
                sns = boto3.client(
                    'sns',
                    region_name='us-east-1',  # atau region SNS kamu
                    aws_access_key_id=os.environ.get("AWS_ACCESS_KEY_ID"),
                    aws_secret_access_key=os.environ.get("AWS_SECRET_ACCESS_KEY"),
                    aws_session_token=os.environ.get("AWS_SESSION_TOKEN")
                )

                topic_arn = os.environ.get("SNS_TOPIC_ARN", "arn:aws:sns:us-east-1:903675765022:techno-sns-payakumbuh-akbar")
                message = "Selamat! Anda berhasil masuk ke dashboard menggunakan token yang valid."
                
                sns.publish(
                    TopicArn=topic_arn,
                    Message=message,
                    Subject="Login Sukses"
                )

            except Exception as e:
                print("Error sending SNS message:", e)

            return {'success': True}
        else:
            error_msg = response.json().get('error', 'Invalid token')
            return {'error': error_msg}, 401

    except requests.RequestException as e:
        print("Exception:", e)
        return {'error': 'Service unavailable. Please try later.'}, 503
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=2000)