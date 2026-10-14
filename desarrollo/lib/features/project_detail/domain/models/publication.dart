import 'project_comment.dart';

/// Publicacion compartida dentro del muro de un proyecto.
///
/// En ROBLE es un avance (`project_updates`, con su imagen o enlace en
/// `project_media`) o, si trae [pollOptions], una encuesta (`polls`).
class Publication {
  const Publication({
    required this.id,
    required this.projectId,
    required this.authorName,
    required this.title,
    required this.content,
    this.imageUrl,
    this.linkUrl,
    this.pollOptions = const [],
    this.pollVotes = const {},
    this.selectedPollOption,
    this.createdAt,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.viewerReacted = false,
    this.comments = const [],
  });

  final String id;
  final String projectId;
  final String authorName;
  final String title;
  final String content;
  final String? imageUrl;
  final String? linkUrl;
  final List<String> pollOptions;
  final Map<String, int> pollVotes;
  final String? selectedPollOption;
  final DateTime? createdAt;
  final int reactionCount;
  final int commentCount;
  final bool viewerReacted;
  final List<ProjectComment> comments;

  /// Las encuestas se votan; los me gusta y comentarios son de los avances.
  bool get isPoll => pollOptions.isNotEmpty;

  Publication copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? linkUrl,
    List<String>? pollOptions,
    Map<String, int>? pollVotes,
    String? selectedPollOption,
    int? reactionCount,
    int? commentCount,
    bool? viewerReacted,
    List<ProjectComment>? comments,
  }) {
    return Publication(
      id: id ?? this.id,
      projectId: projectId,
      authorName: authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      pollOptions: pollOptions ?? this.pollOptions,
      pollVotes: pollVotes ?? this.pollVotes,
      selectedPollOption: selectedPollOption ?? this.selectedPollOption,
      createdAt: createdAt,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      viewerReacted: viewerReacted ?? this.viewerReacted,
      comments: comments ?? this.comments,
    );
  }
}
