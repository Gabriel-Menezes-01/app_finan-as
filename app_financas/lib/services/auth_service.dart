import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static User? get currentUser => _auth.currentUser;
  static String? get userId => _auth.currentUser?.uid;
  
  // Fluxo de mudanças de autenticação
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Registrar novo usuário
  static Future<UserCredential?> registerWithEmailAndPassword(
    String email, 
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualizar o nome do usuário
      await result.user?.updateDisplayName(name);
      
      // Salvar dados localmente
      await _saveUserLocally(email, name);
      await _saveUserPassword(password);
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Se Firebase não estiver disponível, registrar localmente
      return await _registerLocally(email, password, name);
    }
  }

  // Registro local quando Firebase não está disponível
  static Future<UserCredential?> _registerLocally(String email, String password, String name) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar se usuário já existe
    final existingEmail = prefs.getString('user_email');
    if (existingEmail == email) {
      throw 'Este email já está sendo usado por outra conta.';
    }
    
    // Salvar novo usuário localmente
    await _saveUserLocally(email, name);
    await _saveUserPassword(password);
    
    return null; // Retorna null mas o registro é válido
  }

  // Salvar senha localmente (para modo offline)
  static Future<void> _saveUserPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_password', password);
  }
  
  // Login com email e senha
  static Future<UserCredential?> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Salvar dados localmente para sincronização
      await _saveUserLocally(email, result.user?.displayName ?? 'Usuário');
      
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Se Firebase não estiver disponível, tentar login local
      return await _signInLocally(email, password);
    }
  }

  // Login local quando Firebase não está disponível
  static Future<UserCredential?> _signInLocally(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    final savedPassword = prefs.getString('user_password');
    
    if (savedEmail == email && savedPassword == password) {
      // Login local bem-sucedido
      return null; // Retorna null mas o login é válido
    } else {
      throw 'Email ou senha incorretos';
    }
  }

  // Salvar dados do usuário localmente
  static Future<void> _saveUserLocally(String email, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_name', name);
  }
  
  // Logout
  static Future<void> signOut() async {
    try {
      // Limpar dados locais salvos
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_password');
      
      // Tentar fazer logout do Firebase se disponível
      try {
        await _auth.signOut();
      } catch (e) {
        print('Firebase não disponível para logout: $e');
      }
    } catch (e) {
      throw 'Erro ao fazer logout: $e';
    }
  }
  
  // Resetar senha
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Erro inesperado: $e';
    }
  }
  
  // Verificar se usuário está logado
  static bool isLoggedIn() {
    return _auth.currentUser != null;
  }
  
  // Obter nome do usuário atual
  static String getUserName() {
    if (_auth.currentUser?.displayName != null) {
      return _auth.currentUser!.displayName!;
    }
    
    // Tentar obter do armazenamento local
    return _getUserNameFromLocal();
  }
  
  // Obter email do usuário atual
  static String getUserEmail() {
    if (_auth.currentUser?.email != null) {
      return _auth.currentUser!.email!;
    }
    
    // Tentar obter do armazenamento local
    return _getUserEmailFromLocal();
  }

  // Obter nome do usuário do armazenamento local
  static String _getUserNameFromLocal() {
    try {
      // Este é um método síncrono, então vamos retornar um valor padrão
      // e usar um FutureBuilder nos widgets quando necessário
      return 'Usuário';
    } catch (e) {
      return 'Usuário';
    }
  }

  // Obter email do usuário do armazenamento local
  static String _getUserEmailFromLocal() {
    try {
      return '';
    } catch (e) {
      return '';
    }
  }

  // Métodos assíncronos para obter dados locais
  static Future<String> getUserNameAsync() async {
    if (_auth.currentUser?.displayName != null) {
      return _auth.currentUser!.displayName!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Usuário';
  }

  static Future<String> getUserEmailAsync() async {
    if (_auth.currentUser?.email != null) {
      return _auth.currentUser!.email!;
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }
  
  // Verificar se tem sessão local válida
  static Future<bool> hasLocalSession() async {
    try {
      // Primeiro verifica se o Firebase Auth tem usuário
      if (_auth.currentUser != null) {
        return true;
      }
      
      // Se não tem, verifica se existe dados salvos localmente
      final prefs = await SharedPreferences.getInstance();
      final hasUserData = prefs.containsKey('user_email') || 
                         prefs.containsKey('user_name');
      
      return hasUserData;
    } catch (e) {
      return false;
    }
  }
  
  // Tratar exceções do Firebase Auth
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado. Verifique o email digitado.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'Email inválido. Verifique o formato do email.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada. Entre em contato com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida. Entre em contato com o suporte.';
      case 'invalid-credential':
        return 'Credenciais inválidas. Verifique email e senha.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}