extends GenericModalPrompt
class_name AuthorsReplayModalPrompt

func accept() -> void:
	.accept();
	gamelogic.save_file["authors_replay"] = true;
	gamelogic.authors_replay();
	
