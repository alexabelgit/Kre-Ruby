class Back::ImportedQuestionsController < BackController

  def index
    @imported_questions = current_store.imported_questions.latest.paginate(per_page: 20, page: params[:page])
  end

  def update
    @imported_question = current_store.imported_questions.find_by_hashid(params[:id])
    @imported_question.update_attributes(imported_question_params)

    respond_to do |format|
      format.html { redirect_to back_imported_questions_url }
      format.js
    end
  end

  def proceed

    current_store.settings(:background_workers).update_attributes(migrating_imported_questions: true)
    if params[:clear_all]
      current_store.imported_questions.update_all(marked_for_deletion: true)
    else
      flash[:success] = 'Q&A successfully imported. New items will show up in a few moments.'
    end
    MigrateImportedQuestionsWorker.perform_async(current_store.id)

    respond_to do |format|
      format.html { redirect_to (params[:clear_all].present? ? back_imported_questions_url : back_questions_url) }
      format.js
    end
  end

  private

  def imported_question_params
    params.require(:imported_question).permit(:marked_for_deletion)
  end

end
