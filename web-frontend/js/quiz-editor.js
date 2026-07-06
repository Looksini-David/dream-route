// Quiz Editor Backend Integration
class QuizEditorAPI {
    constructor() {
        this.baseURL = 'http://127.0.0.1:8000';
        this.currentQuiz = null;
        this.questions = [];
        this.currentPage = 1;
        this.itemsPerPage = 10;
    }

    // Fetch all quizzes
    async getQuizzes() {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching quizzes:', error);
            throw error;
        }
    }

    // Fetch questions for a specific quiz
    async getQuestions(quizId, page = 1, limit = 10) {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/${quizId}/questions?page=${page}&limit=${limit}`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching questions:', error);
            throw error;
        }
    }

    // Fetch all questions for a quiz (for editing)
    async getAllQuestions(quizId) {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/${quizId}/questions/all`);
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error fetching all questions:', error);
            throw error;
        }
    }

    // Create a new quiz
    async createQuiz(quizData) {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(quizData)
            });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error creating quiz:', error);
            throw error;
        }
    }

    // Create a new question
    async createQuestion(quizId, questionData) {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/${quizId}/questions`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(questionData)
            });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error creating question:', error);
            throw error;
        }
    }

    // Update a question
    async updateQuestion(questionId, questionData) {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/questions/${questionId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(questionData)
            });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error updating question:', error);
            throw error;
        }
    }

    // Delete a question
    async deleteQuestion(questionId) {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/questions/${questionId}`, {
                method: 'DELETE'
            });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error deleting question:', error);
            throw error;
        }
    }

    // Delete a quiz
    async deleteQuiz(quizId) {
        try {
            const response = await fetch(`${this.baseURL}/quizzes/${quizId}`, {
                method: 'DELETE'
            });
            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Error deleting quiz:', error);
            throw error;
        }
    }
}

// Quiz Editor UI Manager
class QuizEditorUI {
    constructor() {
        this.api = new QuizEditorAPI();
        this.selectedQuizId = null;
        this.questions = [];
        this.filteredQuestions = [];
        this.currentPage = 1;
        this.itemsPerPage = 5;
        this.editingQuestionId = null;
        
        this.initializeElements();
        this.bindEvents();
        this.loadData();
    }

    initializeElements() {
        // Quiz selection elements
        this.quizSelect = document.getElementById('quizSelect');
        this.createNewQuizBtn = document.getElementById('createNewQuizBtn');
        this.deleteCurrentQuizBtn = document.getElementById('deleteCurrentQuizBtn');
        this.selectedQuizTitle = document.getElementById('selectedQuizTitle');
        
        // Question form elements
        this.questionForm = document.getElementById('quizForm');
        this.questionInput = document.getElementById('questionInput');
        this.titleInput = document.getElementById('titleInput');
        this.categoryInput = document.getElementById('categoryInput');
        this.optionAInput = document.getElementById('optionAInput');
        this.optionBInput = document.getElementById('optionBInput');
        this.optionCInput = document.getElementById('optionCInput');
        this.optionDInput = document.getElementById('optionDInput');
        this.correctAnswerInput = document.getElementById('correctAnswerInput');
        
        // Table and pagination elements
        this.tableBody = document.getElementById('quizTableBody');
        this.searchInput = document.getElementById('searchInput');
        this.addQuestionBtn = document.getElementById('addQuestionBtn');
        this.quizModal = document.getElementById('quizModal');
        this.closeModalBtn = document.getElementById('closeModalBtn');
        this.cancelModalBtn = document.getElementById('cancelModalBtn');
        this.prevPageBtn = document.getElementById('prevPage');
        this.nextPageBtn = document.getElementById('nextPage');
        this.pageInfo = document.getElementById('pageInfo');
        
        // Loading indicator
        this.loadingDiv = document.createElement('div');
        this.loadingDiv.className = 'text-center py-4';
        this.loadingDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
    }

    bindEvents() {
        // Quiz selection change
        if (this.quizSelect) {
            this.quizSelect.addEventListener('change', (e) => {
                this.selectedQuizId = e.target.value;
                if (this.selectedQuizId) {
                    this.loadQuestions();
                    this.updateQuizControls();
                } else {
                    this.clearTable();
                    this.updateQuizControls();
                }
            });
        }

        // Create new quiz button
        if (this.createNewQuizBtn) {
            this.createNewQuizBtn.addEventListener('click', () => {
                this.showCreateQuizDialog();
            });
        }

        // Delete current quiz button
        if (this.deleteCurrentQuizBtn) {
            this.deleteCurrentQuizBtn.addEventListener('click', () => {
                this.deleteCurrentQuiz();
            });
        }

        // Search functionality
        this.searchInput.addEventListener('input', () => {
            this.filterQuestions();
        });

        // Add question button
        if (this.addQuestionBtn) {
            this.addQuestionBtn.addEventListener('click', () => {
                if (!this.selectedQuizId) {
                    alert('Please select a quiz first');
                    return;
                }
                this.openModal();
            });
        }

        // Modal close buttons
        this.closeModalBtn.addEventListener('click', () => this.closeModal());
        this.cancelModalBtn.addEventListener('click', () => this.closeModal());

        // Form submission
        this.questionForm.addEventListener('submit', (e) => {
            e.preventDefault();
            this.saveQuestion();
        });

        // Pagination buttons
        this.prevPageBtn.addEventListener('click', () => {
            if (this.currentPage > 1) {
                this.currentPage--;
                this.renderTable();
            }
        });

        this.nextPageBtn.addEventListener('click', () => {
            const totalPages = Math.ceil(this.filteredQuestions.length / this.itemsPerPage);
            if (this.currentPage < totalPages) {
                this.currentPage++;
                this.renderTable();
            }
        });
    }

    async loadData() {
        try {
            this.showLoading();
            
            // Load quizzes for selection
            const quizzesResponse = await this.api.getQuizzes();
            this.quizzes = quizzesResponse.quizzes; // Store quizzes for later use
            this.populateQuizSelect(quizzesResponse.quizzes);
            this.updateQuizControls();
            
            this.hideLoading();
        } catch (error) {
            this.hideLoading();
            this.showError('Failed to load quizzes: ' + error.message);
        }
    }

    populateQuizSelect(quizzes) {
        if (!this.quizSelect) return;
        
        this.quizSelect.innerHTML = '<option value="">-- Select a Quiz --</option>';
        quizzes.forEach(quiz => {
            const option = document.createElement('option');
            option.value = quiz.quiz_id;
            option.textContent = `${quiz.domain} - ${quiz.title}`;
            this.quizSelect.appendChild(option);
        });
    }

    createQuizSelector(quizzes) {
        // Create quiz selector UI above the table (without New Quiz and Delete Quiz buttons)
        const selectorDiv = document.createElement('div');
        selectorDiv.className = 'bg-gray-50 p-4 rounded mb-4';
        selectorDiv.innerHTML = `
            <div class="flex flex-wrap items-center gap-4">
                <label class="font-medium text-gray-700">Select Quiz to Edit Questions:</label>
                <select id="quizSelect" class="px-3 py-2 border rounded focus:outline-none focus:ring focus:border-blue-400 min-w-64">
                    <option value="">Select a Quiz</option>
                </select>
                <div id="quizInfo" class="text-sm text-gray-600 hidden"></div>
            </div>
        `;
        
        // Insert before the table container
        const tableContainer = document.querySelector('.bg-white.p-6.rounded.shadow');
        tableContainer.parentNode.insertBefore(selectorDiv, tableContainer);
        
        // Re-initialize elements
        this.quizSelect = document.getElementById('quizSelect');
        this.quizInfo = document.getElementById('quizInfo');
        
        // Populate the selector
        this.populateQuizSelect(quizzes);
        
        // Bind new events
        this.quizSelect.addEventListener('change', (e) => {
            this.selectedQuizId = e.target.value;
            if (this.selectedQuizId) {
                const selectedQuiz = quizzes.find(q => q.quiz_id === this.selectedQuizId);
                if (selectedQuiz) {
                    this.quizInfo.innerHTML = `<i class="fas fa-info-circle mr-1"></i>Domain: ${selectedQuiz.domain} | Title: ${selectedQuiz.title}`;
                    this.quizInfo.classList.remove('hidden');
                }
                this.loadQuestions();
            } else {
                this.quizInfo.classList.add('hidden');
                this.clearTable();
            }
        });
    }

    async loadQuestions() {
        if (!this.selectedQuizId) return;
        
        try {
            this.showLoading();
            const response = await this.api.getAllQuestions(this.selectedQuizId);
            this.questions = response.questions;
            this.filteredQuestions = [...this.questions];
            this.currentPage = 1;
            this.renderTable();
            this.hideLoading();
        } catch (error) {
            this.hideLoading();
            this.showError('Failed to load questions: ' + error.message);
        }
    }

    filterQuestions() {
        const searchTerm = this.searchInput.value.toLowerCase();
        this.filteredQuestions = this.questions.filter(question =>
            question.question_text.toLowerCase().includes(searchTerm) ||
            question.option_a.toLowerCase().includes(searchTerm) ||
            question.option_b.toLowerCase().includes(searchTerm) ||
            question.option_c.toLowerCase().includes(searchTerm) ||
            question.option_d.toLowerCase().includes(searchTerm)
        );
        this.currentPage = 1;
        this.renderTable();
    }

    renderTable() {
        if (!this.tableBody) return;

        this.tableBody.innerHTML = '';
        
        if (this.filteredQuestions.length === 0) {
            this.tableBody.innerHTML = `
                <tr>
                    <td colspan="6" class="px-4 py-8 text-center text-gray-500">
                        ${this.selectedQuizId ? 
                            '<div><i class="fas fa-search text-4xl mb-2 text-gray-300"></i><br>No questions found for this quiz</div>' : 
                            '<div><i class="fas fa-arrow-up text-4xl mb-2 text-gray-300"></i><br>Select a quiz above to view and edit questions</div>'
                        }
                    </td>
                </tr>
            `;
            this.updatePagination(0, 0);
            return;
        }

        const start = (this.currentPage - 1) * this.itemsPerPage;
        const end = start + this.itemsPerPage;
        const pageQuestions = this.filteredQuestions.slice(start, end);

        pageQuestions.forEach((question, index) => {
            const row = document.createElement('tr');
            row.className = 'hover:bg-gray-50';
            row.innerHTML = `
                <td class="px-4 py-2 font-medium">${start + index + 1}</td>
                <td class="px-4 py-2 max-w-xs">
                    <div class="truncate" title="${question.question_text}">
                        ${question.question_text}
                    </div>
                    <small class="text-gray-500">Type: ${question.type || 'General'}</small>
                </td>
                <td class="px-4 py-2">Quiz Question</td>
                <td class="px-4 py-2">
                    <div class="text-xs space-y-1">
                        <div>A: ${question.option_a}</div>
                        <div>B: ${question.option_b}</div>
                        <div>C: ${question.option_c}</div>
                        <div>D: ${question.option_d}</div>
                    </div>
                </td>
                <td class="px-4 py-2">
                    <span class="bg-green-100 text-green-800 px-2 py-1 rounded text-xs font-medium">
                        Option ${question.correct_option}
                    </span>
                </td>
                <td class="px-4 py-2 text-center">
                    <div class="flex justify-center space-x-1">
                        <button class="view-btn bg-blue-500 hover:bg-blue-600 text-white px-2 py-1 rounded text-xs" 
                                data-question-id="${question.question_id}" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="edit-btn bg-yellow-500 hover:bg-yellow-600 text-white px-2 py-1 rounded text-xs" 
                                data-question-id="${question.question_id}" title="Edit Question">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="delete-btn bg-red-500 hover:bg-red-600 text-white px-2 py-1 rounded text-xs" 
                                data-question-id="${question.question_id}" title="Delete Question">
                            <i class="fas fa-trash-alt"></i>
                        </button>
                    </div>
                </td>
            `;
            
            this.tableBody.appendChild(row);
        });

        // Bind edit and delete buttons
        this.bindRowActions();
        
        // Update pagination
        const totalPages = Math.ceil(this.filteredQuestions.length / this.itemsPerPage);
        this.updatePagination(this.currentPage, totalPages);
    }

    bindRowActions() {
        const viewButtons = this.tableBody.querySelectorAll('.view-btn');
        const editButtons = this.tableBody.querySelectorAll('.edit-btn');
        const deleteButtons = this.tableBody.querySelectorAll('.delete-btn');

        viewButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const questionId = e.currentTarget.dataset.questionId;
                this.viewQuestion(questionId);
            });
        });

        editButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const questionId = e.currentTarget.dataset.questionId;
                this.editQuestion(questionId);
            });
        });

        deleteButtons.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const questionId = e.currentTarget.dataset.questionId;
                this.deleteQuestionWithConfirmation(questionId);
            });
        });
    }

    updatePagination(currentPage, totalPages) {
        if (this.pageInfo) {
            this.pageInfo.textContent = totalPages > 0 ? `Page ${currentPage} of ${totalPages}` : 'No data';
        }
        
        if (this.prevPageBtn) {
            this.prevPageBtn.disabled = currentPage <= 1;
        }
        
        if (this.nextPageBtn) {
            this.nextPageBtn.disabled = currentPage >= totalPages || totalPages === 0;
        }
    }

    openModal(questionData = null, isViewMode = false) {
        if (!this.quizModal) return;

        this.editingQuestionId = questionData?.question_id || null;
        
        // Update modal title with icons based on mode
        const modalTitle = this.quizModal.querySelector('h3');
        if (isViewMode) {
            modalTitle.innerHTML = '<i class="fas fa-eye text-blue-600 mr-2"></i>View Question';
        } else if (questionData) {
            modalTitle.innerHTML = '<i class="fas fa-edit text-green-600 mr-2"></i>Edit Question';
        } else {
            modalTitle.innerHTML = '<i class="fas fa-plus text-purple-600 mr-2"></i>Add New Question';
        }
        
        // Get common elements once
        const allInputs = [this.questionInput, this.titleInput, this.categoryInput,
                          this.optionAInput, this.optionBInput, this.optionCInput, 
                          this.optionDInput, this.correctAnswerInput];
        const submitBtn = this.questionForm.querySelector('button[type="submit"]');
        const cancelButton = this.quizModal.querySelector('#cancelModalBtn');
        
        if (questionData) {
            // Populate form with question data - using correct field mapping
            this.questionInput.value = questionData.question_text || '';
            
            // Get quiz title from loaded quizzes
            const quiz = this.quizzes.find(q => q.quiz_id === questionData.quiz_id);
            this.titleInput.value = quiz ? `${quiz.domain} - ${quiz.title}` : `Quiz ${questionData.quiz_id}`;
            
            this.categoryInput.value = questionData.type || 'General';
            this.optionAInput.value = questionData.option_a || '';
            this.optionBInput.value = questionData.option_b || '';
            this.optionCInput.value = questionData.option_c || '';
            this.optionDInput.value = questionData.option_d || '';
            this.correctAnswerInput.value = questionData.correct_option || '';
            
            if (isViewMode) {
                // View mode styling
                allInputs.forEach(input => {
                    input.disabled = true;
                    input.readOnly = true;
                    input.classList.add('bg-gray-50', 'cursor-not-allowed', 'text-gray-700');
                    input.classList.remove('focus:ring', 'focus:border-blue-400');
                });
                
                // Hide save button, style cancel as close
                if (submitBtn) submitBtn.style.display = 'none';
                if (cancelButton) {
                    cancelButton.className = 'bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded flex items-center gap-2';
                    cancelButton.innerHTML = '<i class="fas fa-times mr-2"></i>Close';
                }
            } else {
                // Edit mode styling
                allInputs.forEach(input => {
                    input.disabled = false;
                    input.readOnly = false;
                    input.classList.remove('bg-gray-50', 'cursor-not-allowed');
                    input.classList.add('focus:ring', 'focus:border-blue-400', 'bg-white');
                });
                
                // Show and style save button
                if (submitBtn) {
                    submitBtn.style.display = 'inline-block';
                    submitBtn.innerHTML = '<i class="fas fa-save mr-2"></i>Update Question';
                }
                if (cancelButton) {
                    cancelButton.className = 'bg-gray-300 hover:bg-gray-400 text-gray-800 px-4 py-2 rounded flex items-center gap-2';
                    cancelButton.innerHTML = '<i class="fas fa-times mr-2"></i>Cancel';
                }
            }
        } else {
            // Adding new question - enable all inputs
            this.questionForm.reset();
            this.titleInput.value = this.getSelectedQuizTitle() || 'Quiz Question';
            this.categoryInput.value = 'General';
            
            allInputs.forEach(input => {
                input.disabled = false;
                input.readOnly = false;
                input.classList.remove('bg-gray-50', 'cursor-not-allowed');
                input.classList.add('focus:ring', 'focus:border-blue-400', 'bg-white');
            });
            
            if (submitBtn) {
                submitBtn.style.display = 'inline-block';
                submitBtn.innerHTML = '<i class="fas fa-plus mr-2"></i>Add Question';
            }
            if (cancelButton) {
                cancelButton.innerHTML = '<i class="fas fa-times mr-2"></i>Cancel';
                cancelButton.className = 'bg-gray-300 hover:bg-gray-400 text-gray-800 px-4 py-2 rounded flex items-center gap-2';
            }
            
            // Enable all inputs for new question
            const inputs = this.questionForm.querySelectorAll('input, select');
            inputs.forEach(input => {
                input.disabled = false;
            });
            
            // Show save button
            const saveBtn = this.questionForm.querySelector('button[type="submit"]');
            if (saveBtn) {
                saveBtn.style.display = 'block';
            }
        }

        this.quizModal.classList.remove('hidden');
    }

    getSelectedQuizTitle() {
        if (!this.selectedQuizId || !this.quizzes) return '';
        const selectedQuiz = this.quizzes.find(q => q.quiz_id === this.selectedQuizId);
        return selectedQuiz ? `${selectedQuiz.domain} - ${selectedQuiz.title}` : '';
    }

    updateQuizControls() {
        // Enable/disable buttons based on quiz selection
        const hasSelectedQuiz = !!this.selectedQuizId;
        
        if (this.deleteCurrentQuizBtn) {
            this.deleteCurrentQuizBtn.disabled = !hasSelectedQuiz;
        }
        
        if (this.addQuestionBtn) {
            this.addQuestionBtn.disabled = !hasSelectedQuiz;
        }
        
        // Update quiz title display
        if (this.selectedQuizTitle) {
            if (hasSelectedQuiz) {
                const quizTitle = this.getSelectedQuizTitle();
                this.selectedQuizTitle.textContent = `(${quizTitle})`;
            } else {
                this.selectedQuizTitle.textContent = '';
            }
        }
    }

    async showCreateQuizDialog() {
        // Create modal for quiz creation
        const modalHTML = `
            <div id="createQuizModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                <div class="bg-white rounded-lg p-6 mx-4 max-w-md w-full">
                    <div class="flex items-center mb-4">
                        <div class="flex-shrink-0 w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center">
                            <i class="fas fa-plus text-purple-600"></i>
                        </div>
                        <div class="ml-4">
                            <h3 class="text-lg font-medium text-gray-900">Create New Quiz</h3>
                        </div>
                    </div>
                    
                    <form id="createQuizForm" class="space-y-4">
                        <div>
                            <label for="quizDomain" class="block text-sm font-medium text-gray-700 mb-2">Quiz Domain</label>
                            <input type="text" id="quizDomain" 
                                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                                placeholder='e.g., "Web Development", "Design"' required>
                            <p class="text-xs text-gray-500 mt-1">The subject area or category of the quiz</p>
                        </div>
                        <div>
                            <label for="quizTitle" class="block text-sm font-medium text-gray-700 mb-2">Quiz Title</label>
                            <input type="text" id="quizTitle" 
                                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
                                placeholder='e.g., "Frontend Developer", "UI Designer"' required>
                            <p class="text-xs text-gray-500 mt-1">Specific title for this quiz</p>
                        </div>
                    </form>
                    
                    <div class="flex justify-end space-x-3 mt-6">
                        <button id="cancelCreateQuiz" class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500">
                            Cancel
                        </button>
                        <button id="confirmCreateQuiz" class="px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-md hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500">
                            <i class="fas fa-plus mr-1"></i>Create Quiz
                        </button>
                    </div>
                </div>
            </div>
        `;

        // Add modal to body
        const modalDiv = document.createElement('div');
        modalDiv.innerHTML = modalHTML;
        document.body.appendChild(modalDiv.firstElementChild);

        const modal = document.getElementById('createQuizModal');
        const domainInput = document.getElementById('quizDomain');
        const titleInput = document.getElementById('quizTitle');
        const cancelBtn = document.getElementById('cancelCreateQuiz');
        const confirmBtn = document.getElementById('confirmCreateQuiz');
        const form = document.getElementById('createQuizForm');

        // Focus on domain input
        domainInput.focus();

        const cleanup = () => {
            if (modal && modal.parentNode) {
                modal.parentNode.removeChild(modal);
            }
        };

        // Cancel button
        cancelBtn.addEventListener('click', cleanup);

        // Create quiz button
        confirmBtn.addEventListener('click', async () => {
            const domain = domainInput.value.trim();
            const title = titleInput.value.trim();

            if (!domain || !title) {
                domainInput.focus();
                return;
            }

            try {
                confirmBtn.disabled = true;
                confirmBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Creating...';
                
                const response = await this.api.createQuiz({ domain, title });
                
                cleanup();
                this.showSuccess('Quiz created successfully');
                await this.loadData();
                
                // Select the newly created quiz
                if (response.quiz) {
                    this.quizSelect.value = response.quiz.quiz_id;
                    this.selectedQuizId = response.quiz.quiz_id;
                    this.updateQuizControls();
                    await this.loadQuestions();
                }
            } catch (error) {
                confirmBtn.disabled = false;
                confirmBtn.innerHTML = '<i class="fas fa-plus mr-1"></i>Create Quiz';
                this.showError('Failed to create quiz: ' + error.message);
            }
        });

        // Form submit
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            confirmBtn.click();
        });

        // Close on escape key
        const handleEscape = (e) => {
            if (e.key === 'Escape') {
                cleanup();
                document.removeEventListener('keydown', handleEscape);
            }
        };
        document.addEventListener('keydown', handleEscape);

        // Close on overlay click
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                cleanup();
            }
        });
    }

    async deleteCurrentQuiz() {
        if (!this.selectedQuizId) return;
        
        const quiz = this.quizzes.find(q => q.quiz_id === this.selectedQuizId);
        if (!quiz) return;

        const confirmed = await this.showConfirmationDialog(
            'Delete Quiz',
            `Are you sure you want to delete this quiz and all its questions?`,
            `"${quiz.domain} - ${quiz.title}"`
        );

        if (confirmed) {
            try {
                await this.api.deleteQuiz(this.selectedQuizId);
                this.showSuccess('Quiz deleted successfully');
                this.selectedQuizId = null;
                this.updateQuizControls();
                await this.loadData();
                this.clearTable();
            } catch (error) {
                this.showError('Failed to delete quiz: ' + error.message);
            }
        }
    }

    closeModal() {
        if (this.quizModal) {
            this.quizModal.classList.add('hidden');
            this.editingQuestionId = null;
            
            // Reset form and re-enable all inputs
            this.questionForm.reset();
            const inputs = this.questionForm.querySelectorAll('input, select');
            inputs.forEach(input => {
                input.disabled = false;
            });
            
            // Show save button
            const saveBtn = this.questionForm.querySelector('button[type="submit"]');
            if (saveBtn) {
                saveBtn.style.display = 'block';
            }
            
            // Reset modal title
            const modalTitle = this.quizModal.querySelector('h3');
            if (modalTitle) {
                modalTitle.textContent = 'Add/Edit Question';
            }
        }
    }

    async saveQuestion() {
        if (!this.selectedQuizId) {
            alert('Please select a quiz first');
            return;
        }

        const questionData = {
            question_text: this.questionInput.value.trim(),
            option_a: this.optionAInput.value.trim(),
            option_b: this.optionBInput.value.trim(),
            option_c: this.optionCInput.value.trim(),
            option_d: this.optionDInput.value.trim(),
            correct_option: this.correctAnswerInput.value,
            question_type: this.categoryInput.value.trim() || 'General'
        };

        // Validate inputs
        if (!questionData.question_text || !questionData.option_a || !questionData.option_b || 
            !questionData.option_c || !questionData.option_d || !questionData.correct_option) {
            alert('Please fill in all fields');
            return;
        }

        try {
            if (this.editingQuestionId) {
                // Update existing question
                await this.api.updateQuestion(this.editingQuestionId, questionData);
                this.showSuccess('Question updated successfully');
            } else {
                // Create new question
                questionData.quiz_id = this.selectedQuizId;
                await this.api.createQuestion(this.selectedQuizId, questionData);
                this.showSuccess('Question created successfully');
            }

            this.closeModal();
            await this.loadQuestions();
        } catch (error) {
            this.showError('Failed to save question: ' + error.message);
        }
    }

    async viewQuestion(questionId) {
        const question = this.questions.find(q => q.question_id === questionId);
        if (question) {
            this.openModal(question, true); // true for view mode
        }
    }

    async editQuestion(questionId) {
        const question = this.questions.find(q => q.question_id === questionId);
        if (question) {
            this.openModal(question, false); // false for edit mode
        }
    }

    async deleteQuestionWithConfirmation(questionId) {
        const question = this.questions.find(q => q.question_id === questionId);
        if (!question) {
            this.showError('Question not found');
            return;
        }

        // Create custom confirmation dialog
        const confirmed = await this.showConfirmationDialog(
            'Delete Question',
            `Are you sure you want to delete this question?`,
            `"${question.question_text.substring(0, 100)}${question.question_text.length > 100 ? '...' : ''}"`
        );

        if (confirmed) {
            try {
                await this.api.deleteQuestion(questionId);
                this.showSuccess('Question deleted successfully');
                await this.loadQuestions();
            } catch (error) {
                this.showError('Failed to delete question: ' + error.message);
            }
        }
    }

    // Custom confirmation dialog
    showConfirmationDialog(title, message, details = '') {
        return new Promise((resolve) => {
            // Create modal overlay
            const overlay = document.createElement('div');
            overlay.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
            
            // Create modal content
            overlay.innerHTML = `
                <div class="bg-white rounded-lg p-6 mx-4 max-w-md w-full">
                    <div class="flex items-center mb-4">
                        <div class="flex-shrink-0 w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
                            <i class="fas fa-exclamation-triangle text-red-600"></i>
                        </div>
                        <div class="ml-4">
                            <h3 class="text-lg font-medium text-gray-900">${title}</h3>
                        </div>
                    </div>
                    
                    <div class="mb-4">
                        <p class="text-sm text-gray-700 mb-2">${message}</p>
                        ${details ? `<div class="bg-gray-50 p-3 rounded text-sm text-gray-600 border-l-4 border-red-400">${details}</div>` : ''}
                    </div>
                    
                    <div class="flex justify-end space-x-3">
                        <button id="cancelDelete" class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-200 rounded-md hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-500">
                            Cancel
                        </button>
                        <button id="confirmDelete" class="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500">
                            <i class="fas fa-trash-alt mr-1"></i>Delete
                        </button>
                    </div>
                </div>
            `;

            // Add to body
            document.body.appendChild(overlay);

            // Add event listeners
            const cancelBtn = overlay.querySelector('#cancelDelete');
            const confirmBtn = overlay.querySelector('#confirmDelete');

            const cleanup = () => {
                document.body.removeChild(overlay);
            };

            cancelBtn.addEventListener('click', () => {
                cleanup();
                resolve(false);
            });

            confirmBtn.addEventListener('click', () => {
                cleanup();
                resolve(true);
            });

            // Close on overlay click
            overlay.addEventListener('click', (e) => {
                if (e.target === overlay) {
                    cleanup();
                    resolve(false);
                }
            });

            // Close on escape key
            const handleEscape = (e) => {
                if (e.key === 'Escape') {
                    cleanup();
                    document.removeEventListener('keydown', handleEscape);
                    resolve(false);
                }
            };
            document.addEventListener('keydown', handleEscape);
        });
    }



    clearTable() {
        if (this.tableBody) {
            this.tableBody.innerHTML = `
                <tr>
                    <td colspan="6" class="px-4 py-8 text-center text-gray-500">
                        <div><i class="fas fa-arrow-up text-4xl mb-2 text-gray-300"></i><br>Select a quiz above to view and edit questions</div>
                    </td>
                </tr>
            `;
        }
        this.updatePagination(0, 0);
    }

    showLoading() {
        if (this.tableBody && this.loadingDiv) {
            this.tableBody.innerHTML = '';
            this.tableBody.appendChild(this.loadingDiv);
        }
    }

    hideLoading() {
        if (this.loadingDiv && this.loadingDiv.parentNode) {
            this.loadingDiv.parentNode.removeChild(this.loadingDiv);
        }
    }

    showSuccess(message) {
        this.showNotification(message, 'success');
    }

    showError(message) {
        this.showNotification(message, 'error');
    }

    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `fixed top-4 right-4 z-50 p-4 rounded shadow-lg ${
            type === 'success' ? 'bg-green-500' : 
            type === 'error' ? 'bg-red-500' : 'bg-blue-500'
        } text-white`;
        notification.innerHTML = `
            <div class="flex items-center">
                <i class="fas ${
                    type === 'success' ? 'fa-check-circle' : 
                    type === 'error' ? 'fa-exclamation-circle' : 'fa-info-circle'
                } mr-2"></i>
                <span>${message}</span>
            </div>
        `;

        document.body.appendChild(notification);

        // Remove after 5 seconds
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 5000);
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new QuizEditorUI();
});