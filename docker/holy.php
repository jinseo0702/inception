<?php
$mysqli = mysqli_init();

if (!$mysqli) {
    die('mysqli_init failed');
}

$host = 'db';
$user = 'wordpress';
$password = 'a123456789';
$database = 'wordpress';

$conn = mysqli_real_connect($mysqli, $host, $user, $password, $database);

if ($conn) {
    echo "good";
    mysqli_close($mysqli);
} else {
    echo "fail :" . mysqli_connect_error();
}

/*
제공해주신 추가 정보, 특히 `install.php` 페이지의 "이미 설치됨" 메시지와 `debug.log`의 "Undefined array key HTTP\_HOST" 경고는 문제의 원인을 명확히 하는 데 큰 도움이 됩니다.

**현재까지 파악된 상황 요약:**

1.  **WordPress 설치 완료:** `wp-installing.php` 스크립트는 성공적으로 실행되어 WordPress 설치를 완료했습니다. "이미 설치됨" 메시지가 이를 뒷받침합니다.
2.  **초기 URL 설정 오류:** CLI 환경에서 `wp_install()` 함수가 실행되면서, `$_SERVER['HTTP_HOST']` 변수를 찾을 수 없어 (`debug.log` 경고 내용) WordPress 사이트의 초기 `siteurl`과 `home` 옵션이 잘못된 값 (`http:///var/www/html/wordpress`)으로 설정되었습니다.
3.  **URL 수정 스크립트 작동:** `fix-urls.php` 스크립트는 이 잘못된 `siteurl`과 `home` 값을 올바르게 `http://localhost:8080`으로 변경했습니다.
4.  **메인 페이지 접속 불가:** 그럼에도 불구하고 `localhost:8080` (사이트 메인 페이지)은 여전히 접속되지 않는 상태입니다.

**`localhost:8080` 접속 불가 원인 추론:**

`siteurl`과 `home` 옵션이 올바르게 수정되었음에도 메인 페이지가 작동하지 않는 주된 이유는, **초기 설치 과정에서 다른 데이터베이스 옵션들에도 잘못된 URL (`http:///var/www/html/wordpress`)이 포함되었을 가능성**이 매우 높기 때문입니다. `fix-urls.php` 스크립트는 `siteurl`과 `home` 두 가지 핵심 옵션만 수정하므로, 다른 곳에 남아있는 잘못된 URL들이 사이트의 정상적인 로딩을 방해하고 있을 수 있습니다.

**다음 문제 해결 단계:**

1.  **WordPress 관리자 페이지 로그인 시도:**

      * "이미 설치됨" 페이지에 있는 "로그인" 링크를 클릭하거나, 직접 `http://localhost:8080/wp-login.php` 주소로 접속하여 로그인을 시도해 보세요.
      * **사용자명:** `.env` 파일에 설정된 `WORDPRESS_SUPER_USER` (예: `superuser`)
      * **비밀번호:** `secret/db_password.txt` 파일의 내용 (이 값은 `wp-installing.php`에서 관리자 비밀번호로 사용됨)
      * **결과 확인:**
          * 로그인이 성공하고 WordPress 관리자 대시보드 (`/wp-admin/`)에 정상적으로 접근할 수 있는지 알려주세요.
          * 만약 관리자 대시보드 접근이 가능하다면, "설정" \> "일반" 메뉴에서 "워드프레스 주소 (URL)"와 "사이트 주소 (URL)"가 `http://localhost:8080`으로 올바르게 표시되는지 확인해주세요.

2.  **데이터베이스 `wp_options` 테이블 상세 검사:**

      * `db` (MariaDB) 컨테이너에 접속하여 `wp_options` 테이블 내에 여전히 잘못된 URL 조각 (`/var/www/html/wordpress`)을 포함하고 있는 다른 옵션들이 있는지 확인해야 합니다.
      * 다음 명령어를 사용하여 `db` 컨테이너 내부에서 MariaDB 클라이언트를 실행하고 해당 내용을 검색합니다. (실행 전 `inception/secret/db_root_password.txt` 파일과 `.env` 파일의 `MARIADB_DATABASE` 값을 확인하세요.)
        ```bash
        docker exec -it db mariadb -u root -p$(cat inception/secret/db_root_password.txt) wordpress
        ```
        MariaDB 클라이언트가 실행되면 다음 SQL 쿼리를 입력하세요.
        ```sql
        SELECT option_name, option_value FROM wp_options WHERE option_value LIKE '%/var/www/html/wordpress%';
        ```
      * 이 쿼리 결과로 나오는 `option_name`과 `option_value` 목록을 알려주시면, 어떤 옵션들을 추가로 수정해야 할지 판단하는 데 도움이 됩니다. `siteurl`과 `home` 외에 다른 옵션이 발견되는지 주목해주세요.

3.  **Nginx 로그 확인 (필요시):**

      * `localhost:8080` 접속 시 Nginx 레벨에서 발생하는 오류가 있는지 확인하기 위해 `web` (Nginx) 컨테이너의 로그를 확인합니다.
        ```bash
        docker logs web
        ```

**가장 중요한 다음 단계는 WordPress 관리자 페이지 로그인 시도와 데이터베이스 `wp_options` 테이블 상세 검사입니다.** 이 두 가지 결과를 바탕으로 추가적인 조치를 결정할 수 있습니다. 만약 관리자 페이지 로그인이 가능하다면, 문제는 대부분 데이터베이스 내에 남아있는 잘못된 URL 설정들 때문일 가능성이 높으며, 이를 수정하면 해결될 수 있습니다.
*/
?>

