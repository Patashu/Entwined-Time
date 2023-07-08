extends GenericModalPrompt
class_name GainInsightModalPrompt

func accept() -> void:
	.accept();
	gamelogic.save_file["gain_insight"] = true;
	gamelogic.gain_insight();
