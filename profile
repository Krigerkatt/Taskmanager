<?php
$pageTitle = 'Мой профиль';
require_once 'header.php';
require_once 'data.php';

if (!isset($_SESSION['user_id'])) {
    header('Location: login.php');
    exit;
}

$userId = $_SESSION['user_id'];
$error = '';
$success = '';

try {
    $pdo = new PDO($dsn, $db_user, $db_password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]);
    
    $stmt = $pdo->prepare("SELECT id, username, email, avatar, bio, created_at FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $user = $stmt->fetch();
    
    if (!$user) {
        session_destroy();
        header('Location: login.php');
        exit;
    }
    
} catch (PDOException $e) {
    $error = 'Ошибка загрузки профиля';
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['update_profile'])) {
    $username = trim($_POST['username'] ?? '');
    $bio = trim($_POST['bio'] ?? '');
    
    if ($username) {
        try {
            $stmt = $pdo->prepare("UPDATE users SET username = ?, bio = ? WHERE id = ?");
            $stmt->execute([$username, $bio, $userId]);
            
            $_SESSION['username'] = $username;
            $success = 'Профиль обновлён!';
            $user['username'] = $username;
            $user['bio'] = $bio;
        } catch (PDOException $e) {
            $error = 'Ошибка обновления';
        }
    } else {
        $error = 'Имя пользователя не может быть пустым';
    }
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['upload_avatar'])) {
    if (isset($_FILES['avatar']) && $_FILES['avatar']['error'] === UPLOAD_ERR_OK) {
        $allowed = ['jpg', 'jpeg', 'png', 'gif'];
        $ext = strtolower(pathinfo($_FILES['avatar']['name'], PATHINFO_EXTENSION));
        
        if (in_array($ext, $allowed)) {
            $newName = 'user_' . $userId . '_' . time() . '.' . $ext;
            $uploadPath = $upload_dir . $newName;
            
            if (move_uploaded_file($_FILES['avatar']['tmp_name'], $uploadPath)) {
                if ($user['avatar'] !== 'default.png' && file_exists($upload_dir . $user['avatar'])) {
                    unlink($upload_dir . $user['avatar']);
                }
                
                $stmt = $pdo->prepare("UPDATE users SET avatar = ? WHERE id = ?");
                $stmt->execute([$newName, $userId]);
                
                $_SESSION['user_avatar'] = $upload_url . $newName;
                $user['avatar'] = $newName;
                $success = 'Аватарка загружена!';
            } else {
                $error = 'Ошибка при загрузке файла';
            }
        } else {
            $error = 'Разрешены только JPG, PNG, GIF';
        }
    } else {
        $error = 'Файл не выбран или ошибка загрузки';
    }
}
?>

<div class="profile-container">
  <div class="profile-header">
    <img src="<?= htmlspecialchars($upload_url . $user['avatar']) ?>" 
         alt="Avatar" class="profile-avatar" id="avatarPreview">
    <div class="profile-info">
      <h2><?= htmlspecialchars($user['username']) ?></h2>
      <p class="email"><?= htmlspecialchars($user['email']) ?></p>
      <p class="member-since">
        Регистрация: <?= date('d.m.Y', strtotime($user['created_at'])) ?>
      </p>
    </div>
  </div>
  
  <?php if ($error): ?>
    <p class="error"><?= htmlspecialchars($error) ?></p>
  <?php endif; ?>
  <?php if ($success): ?>
    <p class="success"><?= htmlspecialchars($success) ?></p>
  <?php endif; ?>
  
  <section class="profile-section">
    <h3>Загрузить аватарку</h3>
    <form method="POST" enctype="multipart/form-data">
      <input type="file" name="avatar" accept="image/*" id="avatarInput">
      <button type="submit" name="upload_avatar">Загрузить</button>
    </form>
  </section>
  
  <section class="profile-section">
    <h3>Редактировать профиль</h3>
    <form method="POST">
      <label>Имя пользователя:</label>
      <input type="text" name="username" value="<?= htmlspecialchars($user['username']) ?>" required>
      
      <label>О себе:</label>
      <textarea name="bio" rows="4"><?= htmlspecialchars($user['bio'] ?? '') ?></textarea>
      
      <button type="submit" name="update_profile">Сохранить</button>
    </form>
  </section>
  
  <section class="profile-section">
    <h3>Статистика</h3>
    <?php
    $stmt = $pdo->prepare("SELECT COUNT(*) as total, SUM(complite) as done FROM tasks WHERE user_id = ?");
    $stmt->execute([$userId]);
    $stats = $stmt->fetch();
    $total = (int)$stats['total'];
    $done = (int)$stats['done'];
    $active = $total - $done;
    ?>
    <div class="stats">
      <div class="stat-item">
        <span class="stat-number"><?= $total ?></span>
        <span class="stat-label">Всего задач</span>
      </div>
      <div class="stat-item">
        <span class="stat-number"><?= $active ?></span>
        <span class="stat-label">В процессе</span>
      </div>
      <div class="stat-item">
        <span class="stat-number"><?= $done ?></span>
        <span class="stat-label">Выполнено</span>
      </div>
    </div>
  </section>
</div>

<script>
document.getElementById('avatarInput')?.addEventListener('change', function(e) {
  const file = e.target.files[0];
  if (file) {
    const reader = new FileReader();
    reader.onload = function(e) {
      document.getElementById('avatarPreview').src = e.target.result;
    };
    reader.readAsDataURL(file);
  }
});
</script>
