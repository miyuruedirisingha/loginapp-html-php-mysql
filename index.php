<?php      
include ('config/database.php');

session_start();    

if (isset($_SESSION['username'])) {
    header("Location: welcome.php");
    exit();
}           

?>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - Modern Portal</title>
    <link rel="stylesheet" href="assets/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>
    <div class="container">
        <!-- Left Section -->
        <div class="left-section">
            <div class="illustration">
                <img src="assets/images/NatureLeafLogo.png" alt="Space Astronaut">
            </div>
            <div class="tagline">
                <h2>“Nature’s Power in Every Leaf.”</h2>
                
            </div>
        </div>
        
        <!-- Right Section -->
        <div class="right-section">
            <div class="login-box">
                <h2>Welcome Back</h2>
                <p class="subtitle">Login to continue your journey</p>
                
                <?php if (isset($_GET['error'])): ?>
                    <div class="error-message">
                        <i class="fas fa-exclamation-circle"></i>
                        <?php echo htmlspecialchars($_GET['error']); ?>
                    </div>
                <?php endif; ?>
                
                <form action="login.php" method="post">
                    <div class="input-group">
                        <label for="username">Username</label>
                        <div class="input-wrapper">
                            <i class="fas fa-user"></i>
                            <input type="text" id="username" name="username" placeholder="Enter your username" required>
                        </div>
                    </div>
                    
                    <div class="input-group">
                        <label for="password">Password</label>
                        <div class="input-wrapper">
                            <i class="fas fa-lock"></i>
                            <input type="password" id="password" name="password" placeholder="Enter your password" required>
                        </div>
                    </div>
                    
                    <div class="options">
                        <label class="remember">
                            <input type="checkbox" name="remember">
                            <span>Remember me</span>
                        </label>
                        <a href="#" class="forgot-password">Forgot Password?</a>
                    </div>
                    
                    <button type="submit" class="login-btn">Login</button>
                </form>
                
                <div class="divider">
                    <span>Or continue with</span>
                </div>
                
                <div class="social-login">
                    <button class="social-btn google">
                        <i class="fab fa-google"></i> Google
                    </button>
                    <button class="social-btn facebook">
                        <i class="fab fa-facebook-f"></i> Facebook
                    </button>
                </div>
                
                <p class="signup-text">
                    Don't have an account? <a href="#">Sign up</a>
                </p>
            </div>
        </div>
    </div>
</body>
</html>
