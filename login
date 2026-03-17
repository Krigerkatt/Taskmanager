<?php
$pageTitle = 'Вход';
require_once 'header.php';
require_once 'data.php';

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($email && $password) {
        try {
            $pdo = new PDO($dsn, $db_user, $db_password, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
            ]);
            
            $stmt = $pdo->prepare("SELECT id, username, email, password, avatar FROM users WHERE email = ?");
            $stmt->execute([$email]);
            $user = $stmt->fetch();
            
            if ($user && $user['password'] === $password) {
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['username'] = $user['username'];
                $_SESSION['email'] = $user['email'];
                $_SESSION['user_avatar'] = $upload_url . ($user['avatar'] ?? 'default.png');
                
                header('Location: index.php?page=home');
                exit;
            } else {
                $error = 'Неверный email или пароль';
            }
        } catch (PDOException $e) {
            $error = 'Ошибка подключения к БД';
        }
    } else {
        $error = 'Заполните все поля';
    }
}
?>

<div class="auth-form">
  <h2>Вход в систему</h2>
  <?php if ($error): ?>
    <p class="error"><?= htmlspecialchars($error) ?></p>
  <?php endif; ?>
  <form method="POST">
    <input type="email" name="email" placeholder="Email" required 
           value="<?= htmlspecialchars($_POST['email'] ?? '') ?>">
    <input type="password" name="password" placeholder="Пароль" required>
    <button type="submit">Войти</button>
  </form>
  <p>Нет аккаунта? <a href="register.php">Зарегистрироваться</a></p>
</div>

<?php require_once 'footer.php'; ?>
