-- ============================================================
--  EngPro – Database Schema
--  MySQL 8.0+  |  Charset: utf8mb4
-- ============================================================

CREATE DATABASE IF NOT EXISTS engpro
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE engpro;

-- ------------------------------------------------------------
-- 1. USERS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    email       VARCHAR(150)  NOT NULL UNIQUE,
    password    VARCHAR(255)  NOT NULL,          -- bcrypt hash
    role        ENUM('admin','gv','user') NOT NULL DEFAULT 'user',
    phone       VARCHAR(20)   NULL,
    specialty   ENUM('IELTS','TOEFL','TOEIC') NULL,  -- chỉ dùng cho GV
    avatar      VARCHAR(255)  NULL,
    status      ENUM('active','locked') NOT NULL DEFAULT 'active',
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 2. CATEGORIES  (IELTS Mastery / TOEFL iBT Academic / TOEIC Professional)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS categories (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    type        ENUM('IELTS','TOEFL','TOEIC') NOT NULL,
    description TEXT          NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 3. COURSES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS courses (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    category_id   INT           NOT NULL,
    teacher_id    INT           NOT NULL,
    title         VARCHAR(200)  NOT NULL,
    band_from     VARCHAR(20)   NOT NULL,   -- e.g. "5.5" | "450"
    band_to       VARCHAR(20)   NOT NULL,   -- e.g. "6.5" | "600"
    level         ENUM('Cơ bản','Trung cấp','Nâng cao') NOT NULL DEFAULT 'Cơ bản',
    description   TEXT          NULL,
    price         DECIMAL(12,0) NOT NULL DEFAULT 0,
    status        ENUM('pending','active','locked') NOT NULL DEFAULT 'pending',
    reject_reason TEXT          NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
    FOREIGN KEY (teacher_id)  REFERENCES users(id)      ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 4. LECTURES  (video bài giảng)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lectures (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    course_id        INT           NOT NULL,
    title            VARCHAR(200)  NOT NULL,
    skill            ENUM('Listening','Reading','Writing','Speaking','Grammar','Vocabulary') NOT NULL,
    video_url        VARCHAR(500)  NULL,
    duration_minutes INT           NULL,
    description      TEXT          NULL,
    order_num        INT           NOT NULL DEFAULT 1,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 5. MATERIALS  (tài liệu đính kèm)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS materials (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    course_id   INT           NOT NULL,
    teacher_id  INT           NOT NULL,
    filename    VARCHAR(255)  NOT NULL,
    filepath    VARCHAR(500)  NOT NULL,
    filesize    INT           NULL,       -- bytes
    filetype    VARCHAR(50)   NULL,       -- pdf | docx | xlsx | pptx ...
    description VARCHAR(255)  NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id)  REFERENCES courses(id) ON DELETE CASCADE,
    FOREIGN KEY (teacher_id) REFERENCES users(id)   ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 6. TESTS  (bài kiểm tra)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tests (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    course_id        INT           NOT NULL,
    title            VARCHAR(200)  NOT NULL,
    duration_minutes INT           NOT NULL DEFAULT 30,
    num_questions    INT           NOT NULL DEFAULT 20,
    pass_percent     TINYINT       NOT NULL DEFAULT 60,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 7. QUESTIONS  (câu hỏi trong bài kiểm tra)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS questions (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    test_id         INT           NOT NULL,
    question_text   TEXT          NOT NULL,
    option_a        VARCHAR(500)  NOT NULL,
    option_b        VARCHAR(500)  NOT NULL,
    option_c        VARCHAR(500)  NOT NULL,
    option_d        VARCHAR(500)  NOT NULL,
    correct_answer  ENUM('A','B','C','D') NOT NULL,
    order_num       INT           NOT NULL DEFAULT 1,
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 8. ENROLLMENTS  (đăng ký khóa học)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS enrollments (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT     NOT NULL,
    course_id        INT     NOT NULL,
    progress_percent TINYINT NOT NULL DEFAULT 0,
    status           ENUM('active','completed','paused') NOT NULL DEFAULT 'active',
    enrolled_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_enrollment (user_id, course_id),
    FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 9. LECTURE_PROGRESS  (tiến độ xem video)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lecture_progress (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT          NOT NULL,
    lecture_id  INT          NOT NULL,
    completed   TINYINT(1)   NOT NULL DEFAULT 0,
    watched_at  TIMESTAMP    NULL,
    UNIQUE KEY uk_lp (user_id, lecture_id),
    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    FOREIGN KEY (lecture_id) REFERENCES lectures(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 10. TEST_RESULTS  (kết quả bài kiểm tra)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS test_results (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT            NOT NULL,
    test_id      INT            NOT NULL,
    score        DECIMAL(6,2)   NOT NULL,  -- 7.5 | 82 | 850
    passed       TINYINT(1)     NOT NULL DEFAULT 0,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 11. FEEDBACK  (phản hồi học sinh)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS feedback (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT       NOT NULL,
    course_id   INT       NOT NULL,
    lecture_id  INT       NULL,
    message     TEXT      NOT NULL,
    reply       TEXT      NULL,
    replied_by  INT       NULL,
    replied_at  TIMESTAMP NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    FOREIGN KEY (course_id)  REFERENCES courses(id)  ON DELETE CASCADE,
    FOREIGN KEY (lecture_id) REFERENCES lectures(id) ON DELETE SET NULL,
    FOREIGN KEY (replied_by) REFERENCES users(id)    ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 12. PLACEMENT_RESULTS  (kết quả test xếp loại)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS placement_results (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    user_id            INT           NOT NULL,
    cert_type          ENUM('IELTS','TOEFL','TOEIC') NOT NULL,
    score              DECIMAL(6,2)  NOT NULL,
    recommended_band   VARCHAR(20)   NOT NULL,   -- e.g. "5.5–6.5"
    taken_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 13. MOCK_TESTS  (bài test thử – 1 bài/loại chứng chỉ)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mock_tests (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    cert_type        ENUM('IELTS','TOEFL','TOEIC') NOT NULL,
    title            VARCHAR(200)  NOT NULL,
    duration_minutes INT           NOT NULL DEFAULT 120,
    description      TEXT          NULL,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 14. MOCK_TEST_QUESTIONS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mock_test_questions (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    mock_test_id    INT           NOT NULL,
    skill           ENUM('Listening','Reading','Writing','Speaking') NOT NULL,
    question_text   TEXT          NOT NULL,
    option_a        VARCHAR(500)  NOT NULL,
    option_b        VARCHAR(500)  NOT NULL,
    option_c        VARCHAR(500)  NOT NULL,
    option_d        VARCHAR(500)  NOT NULL,
    correct_answer  ENUM('A','B','C','D') NOT NULL,
    order_num       INT           NOT NULL DEFAULT 1,
    FOREIGN KEY (mock_test_id) REFERENCES mock_tests(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 15. MOCK_TEST_RESULTS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mock_test_results (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT           NOT NULL,
    mock_test_id INT           NOT NULL,
    score        DECIMAL(6,2)  NOT NULL,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)      REFERENCES users(id)      ON DELETE CASCADE,
    FOREIGN KEY (mock_test_id) REFERENCES mock_tests(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 16. PRACTICE_SETS  (bộ đề luyện tập)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS practice_sets (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    cert_type        ENUM('IELTS','TOEFL','TOEIC') NOT NULL,
    title            VARCHAR(200)  NOT NULL,
    skill            ENUM('Listening','Reading','Writing','Speaking','Full') NOT NULL DEFAULT 'Full',
    difficulty       ENUM('Dễ','Trung bình','Khó') NOT NULL DEFAULT 'Trung bình',
    duration_minutes INT           NOT NULL DEFAULT 60,
    description      TEXT          NULL,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 17. PRACTICE_QUESTIONS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS practice_questions (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    practice_set_id  INT           NOT NULL,
    question_text    TEXT          NOT NULL,
    option_a         VARCHAR(500)  NOT NULL,
    option_b         VARCHAR(500)  NOT NULL,
    option_c         VARCHAR(500)  NOT NULL,
    option_d         VARCHAR(500)  NOT NULL,
    correct_answer   ENUM('A','B','C','D') NOT NULL,
    order_num        INT           NOT NULL DEFAULT 1,
    FOREIGN KEY (practice_set_id) REFERENCES practice_sets(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 18. PRACTICE_RESULTS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS practice_results (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT           NOT NULL,
    practice_set_id  INT           NOT NULL,
    score            DECIMAL(6,2)  NOT NULL,
    submitted_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)         REFERENCES users(id)          ON DELETE CASCADE,
    FOREIGN KEY (practice_set_id) REFERENCES practice_sets(id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 19. PAYMENTS  (lịch sử thanh toán)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    user_id      INT            NOT NULL,
    course_id    INT            NOT NULL,
    amount       DECIMAL(12,0)  NOT NULL,
    method       ENUM('momo','vnpay','bank','free') NOT NULL DEFAULT 'free',
    status       ENUM('pending','success','failed') NOT NULL DEFAULT 'pending',
    paid_at      TIMESTAMP      NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)  REFERENCES users(id)   ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- SEED: 3 danh mục mặc định
-- ============================================================
INSERT IGNORE INTO categories (id, name, type, description) VALUES
(1, 'IELTS Mastery',       'IELTS',  'Luyện đủ 4 kỹ năng Nghe, Đọc, Viết, Nói. Lộ trình theo band điểm từ 4.5 đến 8.0+.'),
(2, 'TOEFL iBT Academic',  'TOEFL',  'Chinh phục TOEFL iBT với lộ trình theo dải điểm từ 60 đến 110+. Phù hợp du học Mỹ, Canada.'),
(3, 'TOEIC Professional',  'TOEIC',  'Nắm vững TOEIC Listening & Reading. Lộ trình từ 450 đến 900+, phù hợp môi trường công sở.');
