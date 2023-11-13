from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

app = Flask(__name__)

# MySQL 연결 설정
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://user:project@localhost/user'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.secret_key = 'your_secret_key'
db = SQLAlchemy(app)

class Post(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    content = db.Column(db.Text, nullable=False)
    date_posted = db.Column(db.DateTime, default=datetime.utcnow)

class UserTable(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100),unique=True ,nullable=False)
    password = db.Column(db.String(100), nullable=False)
def find_name(name):
    user = UserTable.query.filter_by(name=name)
    
@app.route('/')
def home():
    if 'username' in session:
        username = session['username']
        posts = Post.query.order_by(Post.date_posted.desc()).all()
        return render_template('index.html', username=username, posts=posts)
    return '안녕하세요! <a href="/login">로그인</a> <a href="/signup">회원가입</a>'

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = UserTable.query.filter_by(name=username, password=password).first()
        if user:
            flash('아이디 중복 입니다.', 'FAIL')
        else:
            adduser = UserTable(name=username, password=password)
            with app.app_context():  # 애플리케이션 컨텍스트 생성
                db.session.add(adduser)
                db.session.commit()
            flash('회원정보가 성공적으로 추가되었습니다!', 'success')
            return redirect(url_for('home'))
        
    return render_template('signup.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        user = UserTable.query.filter_by(name=username, password=password).first()
        # 이 부분은 실제로는 데이터베이스와 비교해야 합니다.

        if user:
            session['username'] = username
            flash('로그인 성공!', 'success')
            return redirect(url_for('home'))
        else:
            flash('로그인 실패. 다시 시도하세요.', 'danger')
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('username', None)
    flash('로그아웃 성공!', 'success')
    return redirect(url_for('home'))

@app.route('/add', methods=['GET', 'POST'])
def add_post():
    if request.method == 'POST':
        title = request.form['title']
        content = request.form['content']
        new_post = Post(title=title, content=content)
        with app.app_context():  # 애플리케이션 컨텍스트 생성
            db.session.add(new_post)
            db.session.commit()
        flash('게시물이 성공적으로 추가되었습니다!', 'success')
        return redirect(url_for('home'))
    return render_template('add_post.html')

if __name__ == '__main__':
    with app.app_context():  # 애플리케이션 컨텍스트 생성
        db.create_all()
    app.run(debug=True)