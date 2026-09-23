import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../home/domain/models/project.dart';
import '../../../home/domain/repositories/i_home_repository.dart';
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../../project_detail/domain/models/project_detail.dart';
import '../../../project_detail/domain/models/project_member.dart';
import '../../../project_detail/domain/models/project_role.dart';
import '../../../project_detail/domain/models/viewer_role.dart';
import '../../../project_detail/domain/repositories/i_project_detail_repository.dart';
import '../../domain/models/person.dart';
import '../../domain/models/project_draft.dart';
import '../../domain/models/project_form_options.dart';
import '../../domain/repositories/i_project_creation_repository.dart';

/// Estado del asistente de creación de proyecto (6 pasos + revisión).
///
/// Depende de tres repositorios a propósito: [IProjectCreationRepository] da
/// los catálogos del formulario, [IHomeRepository] guarda el proyecto en el
/// feed y [IProjectDetailRepository] guarda su ficha completa, porque esas
/// entidades ya viven en sus propias features y no tiene sentido duplicarlas.
class ProjectCreationController extends GetxController with UiLoggy {
  ProjectCreationController(
    this._repository,
    this._homeRepository,
    this._detailRepository,
  );

  final IProjectCreationRepository _repository;
  final IHomeRepository _homeRepository;
  final IProjectDetailRepository _detailRepository;

  static const int totalSteps = 6;

  static const List<String> stepTitles = [
    'Etapa del proyecto',
    'Información básica',
    'Problema',
    'Objetivo y Alcance',
    'Equipo',
    'Recursos',
  ];

  final Rx<ProjectFormOptions> _options = const ProjectFormOptions.empty().obs;
  ProjectFormOptions get options => _options.value;

  /// Paso visible, empezando en 1.
  final RxInt currentStep = 1.obs;
  final RxBool isPublishing = false.obs;

  /// El asistente se abrió desde el formulario de comunidad, así que la
  /// pantalla de éxito ofrece volver allí con el proyecto ya vinculado.
  final RxBool startedFromCommunity = false.obs;

  // Los TextEditingController viven en el viewmodel para que el texto
  // sobreviva al cambio de paso y al ida y vuelta con la revisión.
  final TextEditingController nameField = TextEditingController();
  final TextEditingController descriptionField = TextEditingController();
  final TextEditingController problemField = TextEditingController();
  final TextEditingController objectiveField = TextEditingController();
  final TextEditingController scopeField = TextEditingController();
  final TextEditingController linkField = TextEditingController();

  final RxnString stage = RxnString();
  final RxString name = ''.obs;
  final RxString description = ''.obs;
  final RxString problem = ''.obs;
  final RxString objective = ''.obs;
  final RxString scope = ''.obs;
  final RxList<String> tags = <String>[].obs;
  final RxList<String> roles = <String>[].obs;
  final RxInt maxMembers = 6.obs;
  final RxString availability = 'Part-time'.obs;
  final Rxn<Person> coLeader = Rxn<Person>();
  final RxnString coverUrl = RxnString();
  final RxnString coverName = RxnString();
  final RxList<String> links = <String>[].obs;

  static const int _minMembers = 1;
  static const int _maxMembers = 20;

  @override
  void onInit() {
    _loadOptions();
    super.onInit();
  }

  @override
  void onClose() {
    nameField.dispose();
    descriptionField.dispose();
    problemField.dispose();
    objectiveField.dispose();
    scopeField.dispose();
    linkField.dispose();
    super.onClose();
  }

  Future<void> _loadOptions() async {
    loggy.debug('ProjectCreationController: loading form options');
    _options.value = await _repository.getFormOptions();
    if (options.availabilityOptions.isNotEmpty) {
      availability.value = options.availabilityOptions.first;
    }
  }

  /// Deja el asistente en blanco. Se llama al entrar al flujo, no al volver
  /// desde la pantalla de revisión.
  void startDraft({bool fromCommunity = false}) {
    currentStep.value = 1;
    startedFromCommunity.value = fromCommunity;
    stage.value = null;
    for (final field in [
      nameField,
      descriptionField,
      problemField,
      objectiveField,
      scopeField,
      linkField,
    ]) {
      field.clear();
    }
    name.value = '';
    description.value = '';
    problem.value = '';
    objective.value = '';
    scope.value = '';
    tags.clear();
    roles.clear();
    links.clear();
    maxMembers.value = 6;
    availability.value = options.availabilityOptions.isEmpty
        ? 'Part-time'
        : options.availabilityOptions.first;
    coLeader.value = null;
    coverUrl.value = null;
    coverName.value = null;
  }

  String get currentStepTitle => stepTitles[currentStep.value - 1];

  /// Si el paso visible tiene lo mínimo para avanzar.
  bool get canContinue {
    switch (currentStep.value) {
      case 1:
        return stage.value != null;
      case 2:
        return name.value.trim().isNotEmpty &&
            description.value.trim().isNotEmpty;
      case 3:
        return problem.value.trim().isNotEmpty;
      case 4:
        return objective.value.trim().isNotEmpty;
      default:
        return true;
    }
  }

  void nextStep() {
    if (currentStep.value < totalSteps) currentStep.value++;
  }

  void previousStep() {
    if (currentStep.value > 1) currentStep.value--;
  }

  void goToStep(int step) {
    currentStep.value = step.clamp(1, totalSteps);
  }

  void selectStage(String value) => stage.value = value;

  void addTag(String tag) => tags.add(tag);

  void removeTag(String tag) => tags.remove(tag);

  void addRole(String role) {
    final clean = role.trim();
    if (clean.isEmpty || roles.contains(clean)) return;
    roles.add(clean);
  }

  void removeRole(String role) => roles.remove(role);

  void increaseMembers() {
    if (maxMembers.value < _maxMembers) maxMembers.value++;
  }

  void decreaseMembers() {
    if (maxMembers.value > _minMembers) maxMembers.value--;
  }

  void setAvailability(String value) => availability.value = value;

  void toggleCoLeader(Person person) {
    coLeader.value = coLeader.value?.id == person.id ? null : person;
  }

  void clearCoLeader() => coLeader.value = null;

  /// Candidatos filtrados por el buscador del paso de equipo.
  List<Person> candidatesMatching(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return options.candidates;
    return options.candidates
        .where((person) => person.name.toLowerCase().contains(clean))
        .toList();
  }

  /// Selector de archivos pendiente: sin backend ni plugin de imágenes, se
  /// asigna una portada de ejemplo para que la revisión tenga qué mostrar.
  void pickPlaceholderCover() {
    final slug = name.value.trim().isEmpty
        ? 'proyecto'
        : name.value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    coverUrl.value = 'https://picsum.photos/seed/$slug/400/225';
    coverName.value = 'portada_$slug.png';
  }

  void removeCover() {
    coverUrl.value = null;
    coverName.value = null;
  }

  void addLink(String url) {
    final clean = url.trim();
    if (clean.isEmpty || links.contains(clean)) return;
    links.add(clean);
    linkField.clear();
  }

  void removeLink(String url) => links.remove(url);

  ProjectDraft get draft => ProjectDraft(
    stage: stage.value,
    name: name.value.trim(),
    description: description.value.trim(),
    tags: List.unmodifiable(tags),
    problem: problem.value.trim(),
    objective: objective.value.trim(),
    scope: scope.value.trim(),
    roles: List.unmodifiable(roles),
    maxMembers: maxMembers.value,
    availability: availability.value,
    coLeader: coLeader.value,
    coverUrl: coverUrl.value,
    coverName: coverName.value,
    links: List.unmodifiable(links),
  );

  /// Publica el borrador y lo devuelve ya como [Project] del feed.
  ///
  /// El feed solo guarda el resumen que muestran las tarjetas; el resto del
  /// borrador (problema, objetivo, alcance, equipo, roles y enlaces) se
  /// guarda como [ProjectDetail] para que la ficha del proyecto recién
  /// creado abra con todo lo que se escribió.
  Future<Project> publish() async {
    loggy.debug('ProjectCreationController: publishing ${name.value}');
    isPublishing.value = true;

    // El id es de relleno: ROBLE asigna el real al crear la fila, y
    // `addProject` devuelve el proyecto ya con ese id.
    final draftProject = Project(
      id: '',
      name: name.value.trim(),
      tags: List.unmodifiable(tags),
      stage: stage.value,
      // El creador más el co-líder, si se asignó uno en el paso de equipo.
      memberCount: coLeader.value == null ? 1 : 2,
      // Los roles del paso de equipo también viajan en la entidad del feed:
      // es lo que lee el flujo de postulación.
      requiredRoles: List.unmodifiable(roles),
      imageUrl: coverUrl.value,
      createdAt: DateTime.now(),
      description: description.value.trim(),
    );

    final project = await _homeRepository.addProject(
      draftProject,
      problem: problem.value.trim(),
      objective: objective.value.trim(),
      scope: scope.value.trim().isEmpty ? null : scope.value.trim(),
      maxMembers: maxMembers.value,
      availability: availability.value,
    );
    await _detailRepository.saveDetail(await _buildDetail(project));
    // El feed del home es permanente y no se reconstruye solo al volver.
    await Get.find<HomeController>().getFeed();

    isPublishing.value = false;
    return project;
  }

  /// Traduce el borrador a la ficha completa que muestra la feature de
  /// detalle de proyecto.
  Future<ProjectDetail> _buildDetail(Project project) async {
    final currentUser = await _detailRepository.getCurrentUser();
    final chosenCoLeader = coLeader.value;

    return ProjectDetail(
      projectId: project.id,
      name: project.name,
      coverUrl: project.imageUrl,
      stage: project.stage,
      tags: List.unmodifiable(tags),
      creator: currentUser,
      description: project.description,
      problem: problem.value.trim().isEmpty ? null : problem.value.trim(),
      objective: objective.value.trim().isEmpty
          ? null
          : objective.value.trim(),
      scope: scope.value.trim().isEmpty ? null : scope.value.trim(),
      links: List.unmodifiable(links),
      members: [
        currentUser,
        if (chosenCoLeader != null)
          ProjectMember(
            id: chosenCoLeader.id,
            name: chosenCoLeader.name,
            roleLabel: 'CO-LÍDER',
            isCoLeader: true,
          ),
      ],
      maxMembers: maxMembers.value,
      openRoles: [for (final role in roles) ProjectRole(title: role)],
      availability: availability.value,
      viewerRole: ViewerRole.creator,
    );
  }
}
