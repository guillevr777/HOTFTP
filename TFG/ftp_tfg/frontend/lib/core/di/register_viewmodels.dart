import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../../presentation/viewmodels/auth_view_model.dart';
import 'register_usecases.dart';

List<SingleChildWidget> createViewModelProviders(AppUseCases useCases) {
  return [
    ChangeNotifierProvider(
      create: (_) => AuthViewModel(
        loginUser: useCases.loginUser,
        registerUser: useCases.registerUser,
        signInWithGoogle: useCases.signInWithGoogle,
        logoutUser: useCases.logoutUser,
        restoreSession: useCases.restoreSession,
        observeAuthState: useCases.observeAuthState,
        linkEmailPassword: useCases.linkEmailPassword,
        requestPasswordReset: useCases.requestPasswordReset,
        updateDisplayName: useCases.updateDisplayName,
      ),
    ),
  ];
}
