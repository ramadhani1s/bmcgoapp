import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import (
	"context"
	"errors"
	"log"
	"regexp"
	"strings"
import '../models/user.dart';
import '../models/mentor.dart';

class AuthService {
  // =====================================================
  // BASE URL
  // =====================================================
  static const String baseUrl = 'http://127.0.0.1:8080';

  // =====================================================
  // LOGIN
  // =====================================================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));


// ==================================================
// CHECK ERROR COLUMN
// ==================================================
func isUndefinedColumnError(err error) bool {
	var pgErr *pgconn.PgError

	if errors.As(err, &pgErr) {
		return pgErr.Code == "42703"
	}

	msg := strings.ToLower(err.Error())

	return strings.Contains(msg, "column") &&
		strings.Contains(msg, "does not exist")
}

// ==================================================
// CHECK ERROR TABLE
// ==================================================
func isSchemaMismatchError(err error) bool {
	if err == nil {
		return false
	}
=======
      final data =
          response.body.isNotEmpty
              ? jsonDecode(response.body)
              : {};

      if (response.statusCode == 200) {
        final user =
            User.fromJson(data['user']);

        final prefs =
            await SharedPreferences
                .getInstance();

        await prefs.setString(
          'token',
          data['token'].toString(),
        );

	var pgErr *pgconn.PgError

	if errors.As(err, &pgErr) {
		return pgErr.Code == "42P01"
	}

	msg := strings.ToLower(err.Error())

	return strings.Contains(msg, "relation") &&
		strings.Contains(msg, "does not exist")
}

// ==================================================
// VERIFY PASSWORD
// ==================================================
func verifyPassword(
	ctx context.Context,
	storedPassword string,
	inputPassword string,
	upgradeQuery string,
	upgradeArgs ...any,
) error {
	storedPassword = strings.TrimSpace(storedPassword)
	inputPassword = strings.TrimSpace(inputPassword)

	// bcrypt
	if err := bcrypt.CompareHashAndPassword(
		[]byte(storedPassword),
		[]byte(inputPassword),
	); err == nil {
		return nil
	}

	// plaintext lama
	if storedPassword == inputPassword {
		newHash, hashErr := bcrypt.GenerateFromPassword(
			[]byte(inputPassword),
			bcrypt.DefaultCost,
		)

		if hashErr == nil && upgradeQuery != "" {
			args := append([]any{string(newHash)}, upgradeArgs...)

			_, err := config.DB.Exec(
				ctx,
				upgradeQuery,
				args...,
			)

			if err != nil {
				log.Println("upgrade password gagal:", err)
			}
		}
        await prefs.setString(
          'user',
          jsonEncode(user.toJson()),
        );

        return {
          'success': true,
          'user': user,
          'token': data['token'],
          'message':
              data['message'] ??
              'Login berhasil',
        };
      }

      return {
        'success': false,
        'message':
            data['error'] ??
            'Login gagal',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Server timeout',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Terjadi kesalahan: $e',
      };
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================
  static Future<void> logout() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.remove('token');
    await prefs.remove('user');
  }

  // =====================================================
  // CURRENT USER
  // =====================================================
  static Future<User?> getCurrentUser() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final userJson =
        prefs.getString('user');

	return errors.New("password salah")
}

// ==================================================
// DEFAULT ADMIN
// ==================================================
func seedDefaultAdmin() {
	email := "bimbelbmc@gmail.com"

	var count int

	err := config.DB.QueryRow(
		context.Background(),
		`SELECT COUNT(*) FROM admin WHERE LOWER(email)=LOWER($1)`,
		email,
	).Scan(&count)

	if err != nil {
		return
	}

	if count > 0 {
		return
	}

	hash, _ := bcrypt.GenerateFromPassword(
		[]byte("BMC123"),
		bcrypt.DefaultCost,
	)

	_, _ = config.DB.Exec(
		context.Background(),
		`
		INSERT INTO admin
		(nama,email,password)
		VALUES ($1,$2,$3)
	`,
		"Administrator BMC",
		email,
		string(hash),
	)
}

// ==================================================
// REGISTER
// ==================================================
func Register(user models.User) error {
	if err := validateRegisterInput(user); err != nil {
		return err
	}
    if (userJson == null) {
      return null;
    }

    return User.fromJson(
      jsonDecode(userJson),
    );
  }

  // =====================================================
  // TOKEN
  // =====================================================
  static Future<String?> getToken() async {
    final prefs =
        await SharedPreferences
            .getInstance();

	if user.RoleID == 0 {
		user.RoleID = 3
	}

	hashedPassword, err := bcrypt.GenerateFromPassword(
		[]byte(user.Password),
		bcrypt.DefaultCost,
	)

	if err != nil {
		return errors.New("gagal hash password")
	}

	query := `
		INSERT INTO users
		(
			nama,
			email,
			password,
			role_id
		)
		VALUES ($1,$2,$3,$4)
		RETURNING id
	`

	var userID int

	err = config.DB.QueryRow(
		context.Background(),
		query,
		user.Nama,
		user.Email,
		string(hashedPassword),
		user.RoleID,
	).Scan(&userID)

	if err != nil {
		if strings.Contains(
			strings.ToLower(err.Error()),
			"duplicate",
		) {
			return errors.New("email sudah terdaftar")
		}

		return err
	}

	if user.RoleID == 3 {
		_, _ = config.DB.Exec(
			context.Background(),
			`
			INSERT INTO siswa
			(
				user_id,
				nama_siswa,
				kelas,
				asal_sekolah,
				no_wa,
				alamat
			)
			VALUES ($1,$2,$3,$4,$5,$6)
		`,
			userID,
			user.Nama,
			user.Kelas,
			user.AsalSekolah,
			user.WhatsApp,
			user.Alamat,
		)
	}
    return prefs.getString('token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null &&
        token.isNotEmpty;
  }

  // =====================================================
  // HEADERS
  // =====================================================
  static Future<Map<String, String>>
      getAuthHeaders() async {
    final token = await getToken();

    return {
      'Content-Type':
          'application/json',
      'Accept':
          'application/json',
      if (token != null)
        'Authorization':
            'Bearer $token',
    };
  }

  // =====================================================
  // VALIDATE TOKEN
  // =====================================================
  static Future<bool>
      validateToken() async {
    try {
      final headers =
          await getAuthHeaders();

// ==================================================
// LOGIN
// ==================================================
func Login(email string, password string) (*models.User, error) {
	if strings.TrimSpace(email) == "" ||
		strings.TrimSpace(password) == "" {
		return nil, errors.New("email dan password harus diisi")
	}

	email = strings.ToLower(strings.TrimSpace(email))
	password = strings.TrimSpace(password)

	// ==========================================
	// LOGIN DEFAULT ADMIN
	// ==========================================
	if email == "bimbelbmc@gmail.com" &&
		password == "BMC123" {
		return &models.User{
			ID:       1,
			Nama:     "Administrator BMC",
			Email:    "bimbelbmc@gmail.com",
			RoleID:   1,
			Status:   "aktif",
			Password: "",
		}, nil
	}

	// ==========================================
	// LOGIN DEFAULT MENTOR
	// ==========================================
	if email == "mentor@bmc.local" &&
		password == "mentor123" {
		return &models.User{
			ID:       999999,
			Nama:     "Mentor Sementara",
			Email:    "mentor@bmc.local",
			RoleID:   2,
			Status:   "aktif",
			Password: "",
		}, nil
	}

	// pastikan admin default ada di DB
	seedDefaultAdmin()

	user := &models.User{}

	// ==========================================
	// USERS TABLE
	// ==========================================
	queryUser := `
		SELECT
			id,
			nama,
			email,
			password,
			role_id
		FROM users
		WHERE LOWER(email)=LOWER($1)
		LIMIT 1
	`

	err := config.DB.QueryRow(
		context.Background(),
		queryUser,
		email,
	).Scan(
		&user.ID,
		&user.Nama,
		&user.Email,
		&user.Password,
		&user.RoleID,
	)

	// ==========================================
	// ADMIN TABLE
	// ==========================================
	if err != nil {
		queryAdmin := `
			SELECT
				id,
				nama,
				email,
				password,
				1 as role_id
			FROM admin
			WHERE LOWER(email)=LOWER($1)
			LIMIT 1
		`

		err = config.DB.QueryRow(
			context.Background(),
			queryAdmin,
			email,
		).Scan(
			&user.ID,
			&user.Nama,
			&user.Email,
			&user.Password,
			&user.RoleID,
		)

		if err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return nil, errors.New("email tidak ditemukan")
			}

			return nil, errors.New("gagal login")
		}
	}

	upgradeQuery := `
		UPDATE users
		SET password=$1
		WHERE id=$2
	`

	if user.RoleID == 1 {
		upgradeQuery = `
			UPDATE admin
			SET password=$1
			WHERE id=$2
		`
	}

	if err := verifyPassword(
		context.Background(),
		user.Password,
		password,
		upgradeQuery,
		user.ID,
	); err != nil {
		return nil, err
	}

	user.Password = ""

	return user, nil
}

// ==================================================
// VALIDASI REGISTER
// ==================================================
func validateRegisterInput(user models.User) error {
	nama := strings.TrimSpace(user.Nama)

	if nama == "" {
		return errors.New("nama tidak boleh kosong")
	}

	if len(nama) < 3 {
		return errors.New("nama minimal 3 karakter")
	}

	email := strings.TrimSpace(user.Email)

	if email == "" {
		return errors.New("email tidak boleh kosong")
	}

	emailRegex := regexp.MustCompile(
		`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`,
	)

	if !emailRegex.MatchString(email) {
		return errors.New("format email tidak valid")
	}

	pass := strings.TrimSpace(user.Password)

	if pass == "" {
		return errors.New("password tidak boleh kosong")
	}

	if len(pass) < 6 {
		return errors.New("password minimal 6 karakter")
	}

	if len(pass) > 50 {
		return errors.New("password maksimal 50 karakter")
	}

	return nil
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/profile',
        ),
        headers: headers,
      );

      return response.statusCode ==
          200;
    } catch (_) {
      return false;
    }
  }

  // =====================================================
  // CREATE MENTOR
  // =====================================================
  static Future<Map<String, dynamic>>
      createMentor({
    required String email,
    required String password,
    required String namaMentor,
    String spesialisasi = '',
  }) async {
    try {
      final headers =
          await getAuthHeaders();

      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/mentor/',
            ),
            headers: headers,
            body: jsonEncode({
              'email':
                  email.trim(),
              'password':
                  password.trim(),
              'nama_mentor':
                  namaMentor.trim(),
              'spesialisasi':
                  spesialisasi
                      .trim(),
              'status': 'Aktif',
            }),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      final data =
          response.body.isNotEmpty
              ? jsonDecode(
                  response.body,
                )
              : {};

      if (response.statusCode ==
              200 ||
          response.statusCode ==
              201) {
        return {
          'success': true,
          'message':
              data['message'] ??
              'Mentor berhasil dibuat',
        };
      }

      return {
        'success': false,
        'message':
            data['error'] ??
            'Gagal membuat mentor',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Terjadi kesalahan: $e',
      };
    }
  }

  // =====================================================
  // GET MENTOR
  // =====================================================
  static Future<List<Mentor>>
      getMentors() async {
    try {
      final headers =
          await getAuthHeaders();

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/mentor/',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      if (response.statusCode !=
          200) {
        return [];
      }

      final data =
          jsonDecode(response.body)
              as List;

      return data
          .map(
            (e) => Mentor.fromJson(
              e,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // =====================================================
  // UPDATE MENTOR
  // TIDAK MERUSAK FUNGSI LAMA
  // password opsional
  // =====================================================
  static Future<Map<String, dynamic>>
      updateMentor(
    int id,
    String nama,
    String email,
    String mapel, {
    String password = '',
  }) async {
    try {
      final headers =
          await getAuthHeaders();

      final body = {
        'nama_mentor':
            nama.trim(),
        'email':
            email.trim(),
        'spesialisasi':
            mapel.trim(),
        'status': 'Aktif',
      };

      // hanya kirim password kalau diisi
      if (password.trim().isNotEmpty) {
        body['password'] =
            password.trim();
      }

      final response = await http
          .put(
            Uri.parse(
              '$baseUrl/mentor/$id',
            ),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      final data =
          response.body.isNotEmpty
              ? jsonDecode(
                  response.body,
                )
              : {};

      if (response.statusCode ==
          200) {
        return {
          'success': true,
          'message':
              data['message'] ??
              'Mentor berhasil diupdate',
        };
      }

      return {
        'success': false,
        'message':
            data['error'] ??
            'Gagal update mentor',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Terjadi kesalahan: $e',
      };
    }
  }

  // =====================================================
  // DELETE MENTOR
  // =====================================================
  static Future<Map<String, dynamic>>
      deleteMentor(
    int mentorId,
  ) async {
    try {
      final headers =
          await getAuthHeaders();

      final response = await http
          .delete(
            Uri.parse(
              '$baseUrl/mentor/$mentorId',
            ),
            headers: headers,
          )
          .timeout(
            const Duration(
              seconds: 15,
            ),
          );

      final data =
          response.body.isNotEmpty
              ? jsonDecode(
                  response.body,
                )
              : {};

      if (response.statusCode ==
          200) {
        return {
          'success': true,
          'message':
              data['message'] ??
              'Mentor berhasil dihapus',
        };
      }

      return {
        'success': false,
        'message':
            data['error'] ??
            'Gagal hapus mentor',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Terjadi kesalahan: $e',
      };
    }
  }
}