// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FiScore';

  @override
  String get home => 'Inicio';

  @override
  String get violations => 'Infracciones';

  @override
  String get audits => 'Auditorias';

  @override
  String get training => 'Capacitacion';

  @override
  String get more => 'Mas';

  @override
  String get today => 'Hoy';

  @override
  String get dailyWork => 'Trabajo diario';

  @override
  String get needsAction => 'Necesita accion';

  @override
  String get myWork => 'Mi trabajo';

  @override
  String get teamFollowUp => 'Seguimiento del equipo';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get noActionNeeded => 'Nada necesita accion ahora.';

  @override
  String get startInternalCheck => 'Iniciar revision interna';

  @override
  String get addSite => 'Agregar restaurante';

  @override
  String get viewAudits => 'Ver auditorias';

  @override
  String get profileAndPreferences => 'Perfil y preferencias';

  @override
  String get language => 'Idioma';

  @override
  String get languagePreferenceHelp =>
      'FiScore usara el idioma del dispositivo a menos que elijas uno aqui.';

  @override
  String get useDeviceLanguage => 'Usar idioma del dispositivo';

  @override
  String get deviceLanguageDescription =>
      'Recomendado para dispositivos compartidos y configuracion inicial.';

  @override
  String get englishDescription => 'Mostrar la app en ingles.';

  @override
  String get spanishDescription => 'Mostrar la app en espanol.';

  @override
  String get statusOpen => 'Abierta';

  @override
  String get statusWorking => 'En progreso';

  @override
  String get statusReview => 'Revision';

  @override
  String get statusClosed => 'Cerrada';

  @override
  String get statusUnknown => 'Estado desconocido';

  @override
  String get severityCritical => 'Critica';

  @override
  String get severityMajor => 'Mayor';

  @override
  String get severityMinor => 'Menor';

  @override
  String get severityInformational => 'Informativa';

  @override
  String get severityUnknown => 'Severidad desconocida';

  @override
  String get sourcePublicInspection => 'Inspeccion publica';

  @override
  String get sourceInternalCheck => 'Revision interna';

  @override
  String get sourceManualIssue => 'Problema manual';

  @override
  String get sourceViolation => 'Infraccion';

  @override
  String observed(Object value) {
    return 'Observado: $value';
  }

  @override
  String get assignedToYou => 'Asignado a ti';

  @override
  String assignedTo(Object name) {
    return 'Asignado a $name';
  }

  @override
  String get teamMember => 'miembro del equipo';

  @override
  String get readyForYourReview => 'Listo para tu revision';

  @override
  String get sentBackForUpdate => 'Devuelto para actualizar';

  @override
  String get submitForReview => 'Enviar para revision';

  @override
  String get saveForLater => 'Guardar para despues';

  @override
  String get cancel => 'Cancelar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get refreshPublicInspectionData =>
      'Actualizar datos de inspeccion publica';

  @override
  String get refreshPublicInspectionQuestion =>
      'Actualizar datos de inspeccion publica?';

  @override
  String get refreshPublicInspectionBody =>
      'FiScore buscara las inspecciones publicas y hallazgos mas recientes para este restaurante.';

  @override
  String get backToToday => 'Volver a hoy';

  @override
  String get backToMore => 'Volver a mas';

  @override
  String get backToSites => 'Volver a restaurantes';

  @override
  String get backToViolations => 'Volver a infracciones';

  @override
  String get backToChecks => 'Volver a chequeos';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleManager => 'Gerente';

  @override
  String get roleAuditor => 'Auditor';

  @override
  String get roleStaff => 'Personal';

  @override
  String get requestFailed => 'La solicitud fallo. Intentalo de nuevo.';

  @override
  String get signInRequired => 'Inicia sesion para continuar.';

  @override
  String get noEmailForSignedInUser =>
      'Tu cuenta no tiene un correo electronico.';

  @override
  String get tenantMembershipRequired =>
      'Necesitas acceso a este espacio de trabajo.';

  @override
  String get insufficientTenantRole => 'No tienes permiso para hacer esto.';

  @override
  String get siteAccessRequired => 'Necesitas acceso a este restaurante.';

  @override
  String get unsupportedTeamRole => 'El rol del equipo no es valido.';

  @override
  String get chooseAtLeastOneSite => 'Selecciona al menos un restaurante.';

  @override
  String get chooseAtLeastOneTeammate => 'Selecciona al menos un companero.';

  @override
  String get chooseValidDueDate => 'Selecciona una fecha limite valida.';

  @override
  String get activeSiteNotFound => 'No se encontro el restaurante activo.';

  @override
  String get teamMemberNotFound => 'No se encontro el miembro del equipo.';

  @override
  String get inviteNotFound => 'No se encontro la invitacion.';

  @override
  String get inviteNotValidForUser =>
      'Esta invitacion no corresponde a este usuario.';

  @override
  String get workspaceNotActive => 'Este espacio de trabajo no esta activo.';

  @override
  String get violationNotFound => 'No se encontro la infraccion.';

  @override
  String get closedViolationCannotBeSubmitted =>
      'Una infraccion cerrada no se puede enviar.';

  @override
  String get submittedWorkOnlySentBack =>
      'Solo el trabajo enviado se puede devolver.';

  @override
  String get submittedWorkOnlyClosed =>
      'Solo el trabajo enviado se puede cerrar.';

  @override
  String get closedViolationOnlyReopened =>
      'Solo una infraccion cerrada se puede reabrir.';

  @override
  String get checklistTemplateNotFound =>
      'No se encontro la plantilla de revision.';

  @override
  String get assignedCheckNotFound => 'No se encontro la revision asignada.';

  @override
  String get checkAlreadyFinished => 'Esta revision ya esta terminada.';

  @override
  String get auditNotFound => 'No se encontro la auditoria.';

  @override
  String get libraryContentInvalid =>
      'El tipo de contenido de biblioteca no es valido.';

  @override
  String get libraryItemNotFound => 'No se encontro el elemento de biblioteca.';

  @override
  String get masterRestaurantNotFound =>
      'No se encontro el restaurante maestro.';

  @override
  String get enterAtLeastTwoCharacters => 'Ingresa al menos 2 caracteres.';

  @override
  String get trainingItemNotFound => 'No se encontro la capacitacion.';

  @override
  String get trainingAssignmentNotFound =>
      'No se encontro la asignacion de capacitacion.';

  @override
  String get trainingAlreadyFinished => 'Esta asignacion ya esta terminada.';

  @override
  String get onlyAssignedCanCompleteTraining =>
      'Solo el companero asignado puede completar la capacitacion.';

  @override
  String get trainingAssignmentCancelled => 'Esta asignacion fue cancelada.';

  @override
  String get trainingCompletionSummaryRequired =>
      'Se requiere el resumen de finalizacion.';

  @override
  String get cannotDeactivateYourself => 'No puedes desactivarte a ti mismo.';

  @override
  String get recordNotFound => 'No se encontro el registro.';

  @override
  String get checkInformationAndTryAgain =>
      'Revisa la informacion e intentalo de nuevo.';

  @override
  String get actionNotAvailableRightNow =>
      'Esta accion no esta disponible ahora.';

  @override
  String get signInIntro =>
      'Revisa inspecciones, realiza revisiones y mantén el trabajo correctivo al día.';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get continueWithApple => 'Continuar con Apple';

  @override
  String get continueWithEmail => 'Continuar con correo';

  @override
  String get emailSignIn => 'Inicio con correo';

  @override
  String get signInWithEmail => 'Iniciar sesión con correo';

  @override
  String get emailAddress => 'Correo electrónico';

  @override
  String get emailAddressHint => 'nombre@ejemplo.com';

  @override
  String get emailMeSignInLink => 'Enviarme enlace de acceso';

  @override
  String get sendSignInLink => 'Enviar enlace de acceso';

  @override
  String get checkYourEmail => 'Revisa tu correo';

  @override
  String get secureLinkSentTo => 'Enviamos un enlace seguro a';

  @override
  String get openLinkOnDevice =>
      'Abre el enlace en este dispositivo para continuar.';

  @override
  String get resendLink => 'Reenviar enlace';

  @override
  String get useDifferentEmail => 'Usar otro correo';

  @override
  String get emailSignInHelp =>
      'Te enviaremos un enlace seguro. No se necesita contraseña.';

  @override
  String get or => 'o';

  @override
  String get back => 'Atrás';

  @override
  String get continueAction => 'Continuar';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get createWorkspace => 'Crear espacio de trabajo';

  @override
  String get workspaceName => 'Nombre del espacio';

  @override
  String get workspaceNameHelp =>
      'Usa el nombre del negocio, franquicia o grupo.';

  @override
  String get workspaceNameHint => 'Ejemplo: Kannappan Hospitality';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get search => 'Buscar';

  @override
  String get link => 'Vincular';

  @override
  String get restaurantNameCityZip => 'Nombre, ciudad o ZIP del restaurante';

  @override
  String get searchPublicRestaurantRecords =>
      'Buscar registros públicos del restaurante';

  @override
  String get restaurantName => 'Nombre del restaurante';

  @override
  String get streetAddress => 'Dirección';

  @override
  String get city => 'Ciudad';

  @override
  String get state => 'Estado';

  @override
  String get zip => 'ZIP';

  @override
  String get addRestaurant => 'Agregar restaurante';

  @override
  String get addRestaurantManually => 'Agregar restaurante manualmente';

  @override
  String get backToSearch => 'Volver a buscar';

  @override
  String get account => 'Cuenta';

  @override
  String get manageTeammate => 'Administrar compañero';

  @override
  String get email => 'Correo';

  @override
  String get role => 'Rol';

  @override
  String get allSites => 'Todos los restaurantes';

  @override
  String get selected => 'Seleccionado';

  @override
  String get sendInvite => 'Enviar invitación';

  @override
  String get creatingInvite => 'Creando invitación...';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get resendInviteLink => 'Reenviar enlace de invitación';

  @override
  String get cancelInvite => 'Cancelar invitación';

  @override
  String get deactivateAccess => 'Desactivar acceso';

  @override
  String get couldNotLoadPendingInvites =>
      'No pudimos cargar tus invitaciones pendientes. Inténtalo de nuevo.';

  @override
  String get invitationLookupFailed => 'Falló la búsqueda de invitaciones.';

  @override
  String get teamAccessInactive => 'Acceso al equipo inactivo';

  @override
  String get inactiveAccessHelp =>
      'Tu cuenta no está activa en este espacio de trabajo. Pide a tu gerente una nueva invitación si necesitas acceso otra vez.';

  @override
  String welcomeUser(Object name) {
    return 'Bienvenido, $name';
  }

  @override
  String get noTeamInvitesCreateWorkspace =>
      'No encontramos invitaciones para este correo. Crea un nuevo espacio de FiScore para comenzar.';

  @override
  String get joinYourTeam => 'Únete a tu equipo';

  @override
  String get returnToYourTeam => 'Regresa a tu equipo';

  @override
  String get removeAssignment => 'Quitar asignación';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get choosePhoto => 'Elegir foto';

  @override
  String get chooseVideo => 'Elegir video';

  @override
  String get processedAfterUpload => 'Se procesa después de subir';

  @override
  String get shortClipsOnly => 'Solo videos cortos, limitados antes de subir';

  @override
  String get addPhoto => 'Agregar foto';

  @override
  String get addVideo => 'Agregar video';

  @override
  String get moreActions => 'Más';

  @override
  String get addTeamUpdate => 'Agrega una actualización del equipo.';

  @override
  String get postNote => 'Publicar nota';

  @override
  String get deletePost => 'Eliminar nota';

  @override
  String get saveProgress => 'Guardar progreso';

  @override
  String get savedForLater => 'Guardado para más tarde.';

  @override
  String get submittedForReview => 'Enviado para revisión.';

  @override
  String get trainingAssignedForViolation =>
      'Capacitación asignada para esta infracción.';

  @override
  String get sendBack => 'Devolver';

  @override
  String get closeViolation => 'Cerrar infracción';

  @override
  String get reopen => 'Reabrir';

  @override
  String get addReviewFeedback => 'Agrega comentarios de revisión.';

  @override
  String get videoAttached => 'Video adjunto';

  @override
  String get backToPublicInspections => 'Volver a inspecciones públicas';

  @override
  String get loadMoreInspections => 'Cargar más inspecciones';

  @override
  String get reportUploaded => 'Reporte cargado.';

  @override
  String get reportStored => 'Reporte guardado';

  @override
  String findingCount(Object count) {
    return '$count hallazgos';
  }

  @override
  String gradeValue(Object value) {
    return 'Grado $value';
  }

  @override
  String scoreValue(Object value) {
    return 'Puntaje $value';
  }

  @override
  String get inspectionDate => 'Fecha de inspección';

  @override
  String get score => 'Puntaje';

  @override
  String get grade => 'Grado';

  @override
  String get internal => 'Interna';

  @override
  String get public => 'Pública';

  @override
  String get startCheck => 'Iniciar revisión';

  @override
  String get assignCheck => 'Asignar revisión';

  @override
  String get checkAssigned => 'Revisión asignada.';

  @override
  String get checkReassigned => 'Revisión reasignada.';

  @override
  String get assignedCheckCancelled => 'Revisión asignada cancelada.';

  @override
  String get checklistAddedToMyLibrary => 'Lista agregada a Mi biblioteca.';

  @override
  String get keep => 'Mantener';

  @override
  String get cancelCheck => 'Cancelar revisión';

  @override
  String get loadMoreActiveChecks => 'Cargar más revisiones activas';

  @override
  String get viewMoreCompletedChecks => 'Ver más revisiones completadas';

  @override
  String get loadMoreCompletedChecks => 'Cargar más revisiones completadas';

  @override
  String get couldNotStartAssignedCheck =>
      'No se pudo iniciar el chequeo asignado. Inténtalo de nuevo.';

  @override
  String get couldNotStartCheck =>
      'No se pudo iniciar el chequeo. Inténtalo de nuevo.';

  @override
  String get couldNotReassignCheck =>
      'No se pudo reasignar este chequeo. Inténtalo de nuevo.';

  @override
  String get couldNotCancelCheck =>
      'No se pudo cancelar este chequeo. Inténtalo de nuevo.';

  @override
  String get cancelThisCheckQuestion => '¿Cancelar esta revisión?';

  @override
  String get cancelAssignedCheckQuestion => '¿Cancelar revisión asignada?';

  @override
  String get cancelSelfStartedCheckBody =>
      'Esta revisión en progreso se cancelará y se quitará de tu lista.';

  @override
  String get cancelAssignedCheckBody =>
      'El compañero ya no tendrá que completar esta revisión.';

  @override
  String get assignedChecks => 'Revisiones asignadas';

  @override
  String get assignedToMe => 'Asignado a mí';

  @override
  String get inProgress => 'En progreso';

  @override
  String get completedChecks => 'Revisiones completadas';

  @override
  String get noCompletedChecksYet => 'No hay revisiones completadas';

  @override
  String get runInternalCheckHelp =>
      'Realiza una revisión interna para identificar problemas antes de una inspección.';

  @override
  String get view => 'Ver';

  @override
  String get checklist => 'Lista de revisión';

  @override
  String get assignTo => 'Asignar a';

  @override
  String get dueDate => 'Fecha límite';

  @override
  String get optionalNote => 'Nota opcional';

  @override
  String get auditOptionalNoteHint => 'Ejemplo: Completar antes del cierre.';

  @override
  String get searchTeamMembers => 'Buscar miembros del equipo';

  @override
  String get backToLastSection => 'Volver a la última sección';

  @override
  String get backToReview => 'Volver a revisión';

  @override
  String get completeMissingItems => 'Completar elementos faltantes';

  @override
  String get submitting => 'Enviando...';

  @override
  String get submitAudit => 'Enviar revisión';

  @override
  String get previous => 'Anterior';

  @override
  String get saveAndExit => 'Guardar y salir';

  @override
  String get save => 'Guardar';

  @override
  String get pass => 'Pasa';

  @override
  String get attention => 'Atención';

  @override
  String get notApplicable => 'N/A';

  @override
  String get myLibrary => 'Mi biblioteca';

  @override
  String get exploreFiScore => 'Explorar FiScore';

  @override
  String get exploreFiScoreLibrary => 'Explorar biblioteca FiScore';

  @override
  String get trainingAssigned => 'Capacitación asignada.';

  @override
  String get cancelThisAssignmentQuestion => '¿Cancelar esta asignación?';

  @override
  String get cancelThisAssignmentBody =>
      'Esto quita la capacitación de la lista activa del compañero.';

  @override
  String get keepAssignment => 'Mantener asignación';

  @override
  String get cancelAssignment => 'Cancelar asignación';

  @override
  String get trainingAssignmentCancelledMessage =>
      'Asignación de capacitación cancelada.';

  @override
  String get loadMoreAssignedTraining => 'Cargar más capacitaciones asignadas';

  @override
  String get backToTraining => 'Volver a capacitación';

  @override
  String get loadMoreAssignments => 'Cargar más asignaciones';

  @override
  String get loadMoreActiveAssignments => 'Cargar más asignaciones activas';

  @override
  String get couldNotUpdateTrainingLibrary =>
      'No se pudo actualizar la biblioteca de capacitación.';

  @override
  String get addLessonToMyLibrary => 'Agregar lección a Mi biblioteca';

  @override
  String get startTraining => 'Iniciar capacitación';

  @override
  String get done => 'Listo';

  @override
  String get trainingLabel => 'Capacitación';

  @override
  String get trainingOptionalNoteHint =>
      'Ejemplo: Completar antes del próximo turno de preparación.';

  @override
  String get searchTraining => 'Buscar capacitación';

  @override
  String get moreFilters => 'Más filtros';

  @override
  String get assignmentActions => 'Acciones de asignación';

  @override
  String get close => 'Cerrar';

  @override
  String get pause => 'Pausar';

  @override
  String get play => 'Reproducir';

  @override
  String get playVideo => 'Reproducir video';

  @override
  String get next => 'Siguiente';

  @override
  String get review => 'Revisión';

  @override
  String get responsesSaveAutomatically =>
      'Las respuestas se guardan automáticamente.';

  @override
  String get continueAndFinishFromReview =>
      'Puedes continuar ahora y terminar elementos abiertos desde la revisión.';

  @override
  String get describeIssueBeforeSubmitting =>
      'Describe este problema antes de enviar.';

  @override
  String get confirmYourEmail => 'Confirma tu correo';

  @override
  String get confirmEmailLinkHelp =>
      'Por seguridad, ingresa el correo que recibió este enlace de acceso.';

  @override
  String get emailLinkCouldNotBeUsed =>
      'No se pudo usar este enlace. Solicita un nuevo correo de acceso.';

  @override
  String get setUpWorkspace => 'Configura tu espacio de FiScore';

  @override
  String signedInWorkspaceHelp(Object displayName) {
    return 'Sesión iniciada como $displayName. Crea un espacio para el negocio o grupo de restaurantes que administra las ubicaciones.';
  }

  @override
  String get workspaceOwnerGuidance =>
      'Solo un propietario o administrador debe crear un espacio. El personal del restaurante debe unirse después con una invitación del propietario.';

  @override
  String get findRestaurantToImportHistory =>
      'Busca tu restaurante para importar el historial de inspecciones públicas.';

  @override
  String get enterRestaurantToStartChecks =>
      'Ingresa la ubicación del restaurante para comenzar revisiones internas.';

  @override
  String get searchResults => 'Resultados de búsqueda';

  @override
  String get noMatchingRestaurants =>
      'No se encontraron restaurantes. Intenta otra búsqueda o agrega esta ubicación manualmente.';

  @override
  String get publicInspectionHistoryCanBeLinkedLater =>
      'El historial de inspecciones públicas se puede vincular más adelante.';

  @override
  String get restaurant => 'Restaurante';

  @override
  String inspectionCount(Object count) {
    return '$count inspecciones';
  }

  @override
  String inspectionCountLatest(Object count, Object date) {
    return '$count inspecciones - Última $date';
  }

  @override
  String get team => 'Equipo';

  @override
  String get teamIntro =>
      'Invita personal y controla a qué restaurantes pueden acceder.';

  @override
  String get inviteTeammate => 'Invitar compañero';

  @override
  String get enterValidStaffEmail => 'Ingresa un correo válido del personal.';

  @override
  String get chooseAtLeastOneSiteForInvite =>
      'Selecciona al menos un restaurante para esta invitación.';

  @override
  String inviteSentTo(Object email) {
    return 'Invitación enviada a $email.';
  }

  @override
  String get inviteSavedEmailFailed =>
      'La invitación se guardó, pero no se pudo enviar el correo.';

  @override
  String get couldNotCreateInvite =>
      'No se pudo crear la invitación. Inténtalo de nuevo.';

  @override
  String signInLinkResentTo(Object email) {
    return 'Enlace de acceso reenviado a $email.';
  }

  @override
  String get couldNotResendSignInLink =>
      'No se pudo reenviar el enlace de acceso.';

  @override
  String get cancelInvitationQuestion => '¿Cancelar invitación?';

  @override
  String cancelInvitationBody(Object email) {
    return '$email ya no podrá unirse con esta invitación.';
  }

  @override
  String get keepInvitation => 'Mantener invitación';

  @override
  String invitationCanceledFor(Object email) {
    return 'Invitación cancelada para $email.';
  }

  @override
  String deactivateMemberQuestion(Object name) {
    return '¿Desactivar a $name?';
  }

  @override
  String get deactivateMemberBody =>
      'Perderá acceso a este espacio. Su actividad anterior seguirá visible.';

  @override
  String get deactivate => 'Desactivar';

  @override
  String get keepAccess => 'Mantener acceso';

  @override
  String memberDeactivated(Object name) {
    return '$name fue desactivado.';
  }

  @override
  String editMember(Object name) {
    return 'Editar $name';
  }

  @override
  String get editInvitation => 'Editar invitación';

  @override
  String accessUpdatedFor(Object name) {
    return 'Acceso actualizado para $name.';
  }

  @override
  String invitationUpdatedFor(Object email) {
    return 'Invitación actualizada para $email.';
  }

  @override
  String get profile => 'Perfil';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get fiScoreUser => 'Usuario de FiScore';

  @override
  String violationMovedToStatus(Object status) {
    return 'Infracción movida a $status.';
  }

  @override
  String get couldNotUpdateViolation =>
      'No se pudo actualizar la infracción. Inténtalo de nuevo.';

  @override
  String get couldNotSaveResponse =>
      'No se pudo guardar la respuesta. Inténtalo de nuevo.';

  @override
  String get enterFixBeforeSubmit =>
      'Ingresa qué se corrigió antes de enviar para revisión.';

  @override
  String get couldNotSubmitResponse =>
      'No se pudo enviar la respuesta. Inténtalo de nuevo.';

  @override
  String get closedAfterManagerReview =>
      'Cerrada después de la revisión del gerente.';

  @override
  String get sendBackForChanges => 'Devolver para cambios';

  @override
  String get sendBackHelp => 'Indica al equipo qué debe corregirse.';

  @override
  String get couldNotAddChecklist =>
      'No se pudo agregar esta lista. Inténtalo de nuevo.';

  @override
  String get chooseChecklist => 'Elige una lista.';

  @override
  String get chooseTeammate => 'Elige un compañero.';

  @override
  String get couldNotAssignCheck =>
      'No se pudo asignar este chequeo. Inténtalo de nuevo.';

  @override
  String get assignCheckHelp =>
      'Elige una lista y un compañero para completarla.';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get inThreeDays => 'En 3 días';

  @override
  String get inOneWeek => 'En 1 semana';

  @override
  String get inTwoWeeks => 'En 2 semanas';

  @override
  String get inOneMonth => 'En 1 mes';

  @override
  String get chooseDate => 'Elegir fecha';

  @override
  String chooseDateWithDate(Object date) {
    return 'Elegir fecha ($date)';
  }

  @override
  String get completeBeforeClosingShiftExample =>
      'Ejemplo: Completar antes del cierre.';

  @override
  String get reassignCheck => 'Reasignar chequeo';

  @override
  String get reassign => 'Reasignar';

  @override
  String get startedByYou => 'Iniciado por ti';

  @override
  String startedBy(Object name) {
    return 'Iniciado por $name';
  }

  @override
  String get selfStarted => 'Iniciado por cuenta propia';

  @override
  String get overdue => 'Vencido';

  @override
  String get dueToday => 'Vence hoy';

  @override
  String get dueTomorrow => 'Vence mañana';

  @override
  String dueShortDate(Object date) {
    return 'Vence $date';
  }

  @override
  String get completed => 'Completado';

  @override
  String completedShortDate(Object date) {
    return 'Completado $date';
  }

  @override
  String get start => 'Iniciar';

  @override
  String get resume => 'Continuar';

  @override
  String get assignTraining => 'Asignar capacitación';

  @override
  String get assignTrainingMyHelp =>
      'Elige capacitación de tu biblioteca y asígnala.';

  @override
  String get assignTrainingExploreHelp =>
      'Agrega capacitación de FiScore a la biblioteca del equipo.';

  @override
  String get teamProgress => 'Progreso del equipo';

  @override
  String teamProgressSummary(Object open, Object overdue, Object completed) {
    return '$open abiertas  |  $overdue vencidas  |  $completed completadas';
  }

  @override
  String get openStatus => 'Abiertas';

  @override
  String get cancelled => 'Canceladas';

  @override
  String cancelledCount(Object count) {
    return 'Canceladas ($count)';
  }

  @override
  String get all => 'Todo';

  @override
  String get nothingInThisView => 'No hay nada en esta vista';

  @override
  String get noTrainingAssignmentsToFollowUp =>
      'No hay capacitaciones asignadas para revisar.';

  @override
  String get noMatchingTraining => 'No hay capacitación coincidente';

  @override
  String get tryDifferentSearchTerm => 'Prueba con otra búsqueda.';

  @override
  String get noTrainingInMyLibrary => 'No hay capacitación en Mi biblioteca';

  @override
  String get exploreTrainingLibraryHelp =>
      'Explora la Biblioteca FiScore para agregar capacitación al equipo.';

  @override
  String get couldNotLoadFiScoreLibrary =>
      'No se pudo cargar la Biblioteca FiScore';

  @override
  String get pleaseTryAgainShortly => 'Inténtalo de nuevo pronto.';

  @override
  String get update => 'Actualizar';

  @override
  String get added => 'Agregado';

  @override
  String get add => 'Agregar';

  @override
  String get assign => 'Asignar';

  @override
  String get createdByYourTeam => 'Creado por tu equipo';

  @override
  String get microLearning => 'Microaprendizaje';

  @override
  String get minUnit => 'min';

  @override
  String get updateAvailableInFiScoreLibrary =>
      'Actualización disponible en la Biblioteca FiScore';

  @override
  String get completedLabel => 'Completado';

  @override
  String selectTeamMembers(Object count, Object pluralSuffix) {
    return 'Seleccionar $count compañero$pluralSuffix';
  }

  @override
  String get noDueDate => 'Sin fecha límite';

  @override
  String get chooseTrainingItemToAssign =>
      'Elige una capacitación para asignar.';

  @override
  String get chooseAtLeastOneTeammateToAssign =>
      'Elige al menos un compañero para asignar.';

  @override
  String get couldNotAssignTraining =>
      'No se pudo asignar la capacitación. Inténtalo de nuevo.';

  @override
  String get forThisViolation => 'Para esta infracción';

  @override
  String get noActiveTrainingItems =>
      'No hay capacitaciones activas disponibles.';

  @override
  String get fixesReadyForReview => 'Correcciones listas para revisión';

  @override
  String get myAssignedFixes => 'Mis correcciones asignadas';

  @override
  String get myChecks => 'Mis chequeos';

  @override
  String get myTraining => 'Mi capacitación';

  @override
  String get overdueTraining => 'Capacitación vencida';

  @override
  String get overdueChecks => 'Chequeos vencidos';

  @override
  String get actionInbox => 'Bandeja de acciones';

  @override
  String get reviewSubmittedFixesHelp =>
      'Revisa correcciones enviadas y cierra el trabajo.';

  @override
  String get completeAssignedFixesHelp =>
      'Completa las correcciones asignadas a ti.';

  @override
  String get continueChecksHelp => 'Continúa chequeos iniciados o asignados.';

  @override
  String get completeAssignedCoachingHelp =>
      'Completa la capacitación asignada a ti.';

  @override
  String get followUpOverdueTrainingHelp =>
      'Da seguimiento a capacitación vencida.';

  @override
  String get followUpOverdueChecksHelp => 'Da seguimiento a chequeos vencidos.';

  @override
  String get workNeedsAttentionHelp => 'Trabajo que necesita tu atención.';

  @override
  String get openSite => 'Abrir restaurante';

  @override
  String get startACheck => 'Iniciar un chequeo';

  @override
  String get chooseChecklistForSite =>
      'Elige una lista que tu equipo usa en este restaurante.';

  @override
  String get addCuratedChecklistsHelp =>
      'Agrega listas de FiScore a la biblioteca del equipo.';

  @override
  String get searchChecklists => 'Buscar listas';

  @override
  String get noChecklistsInMyLibrary => 'No hay listas en Mi biblioteca';

  @override
  String get exploreChecklistLibraryHelp =>
      'Explora la Biblioteca FiScore para agregar una lista que tu equipo pueda usar.';

  @override
  String get askManagerToAddChecklist =>
      'Pide a un gerente que agregue una lista interna para este restaurante.';

  @override
  String get noMatchingChecklists => 'No hay listas coincidentes';

  @override
  String get reviewChecklist => 'Revisar lista';

  @override
  String get submitCheck => 'Enviar chequeo';

  @override
  String get couldNotAddTraining =>
      'No se pudo agregar esta capacitación. Inténtalo de nuevo.';

  @override
  String get trainingAssignedMessage => 'Capacitación asignada.';

  @override
  String get cancelTrainingAssignmentBody =>
      'El miembro del equipo ya no tendrá que completar esta capacitación. La asignación queda en el historial.';

  @override
  String get couldNotCancelTraining =>
      'No se pudo cancelar la capacitación. Inténtalo de nuevo.';

  @override
  String get noTrainingAssigned => 'No hay capacitación asignada';

  @override
  String get assignedLearningWillAppear =>
      'La capacitación asignada aparecerá aquí.';

  @override
  String get forManagers => 'Para gerentes';

  @override
  String get assignAndMonitorTrainingHelp =>
      'Asigna capacitación y monitorea la finalización.';

  @override
  String get trainingUnavailableManagerHelp =>
      'Esta asignación usa contenido que no está actualmente en Mi biblioteca. Agrega la lección de FiScore y vuelve a abrirla, o asigna una nueva versión.';

  @override
  String get trainingUnavailableStaffHelp =>
      'Esta capacitación aún no está disponible. Contacta a tu gerente.';

  @override
  String questionCheck(Object count) {
    return 'Chequeo de $count pregunta(s)';
  }

  @override
  String get assignedForFollowUp => 'Asignado para seguimiento';

  @override
  String get youWillCover => 'Verás';

  @override
  String assignedToName(Object name) {
    return 'Asignado a $name.';
  }

  @override
  String get watchRequiredVideo => 'Mira el video requerido para continuar.';

  @override
  String get quickCheck => 'Chequeo rápido';

  @override
  String get complete => 'Completar';

  @override
  String quickCheckProgress(Object current, Object total) {
    return 'Chequeo rápido $current de $total';
  }

  @override
  String get checkAnswer => 'Revisar respuesta';

  @override
  String get finish => 'Finalizar';

  @override
  String get trainingComplete => 'Capacitación completada';

  @override
  String get completedBy => 'Completado por';

  @override
  String get topicsCovered => 'Temas cubiertos';

  @override
  String get quickCheckRecorded =>
      'Chequeo rápido completado. Esta finalización quedó registrada.';
}
