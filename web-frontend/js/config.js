/**
 * API Configuration for DreamRoute Frontend
 * Central configuration for all API endpoints
 */

// API Base URL - Change this based on your environment
const API_BASE_URL = 'http://127.0.0.1:8000';

// API Endpoints Configuration
const API_CONFIG = {
    // Base URL
    BASE_URL: API_BASE_URL,
    
    // Authentication Endpoints
    AUTH: {
        LOGIN: `${API_BASE_URL}/admin/login`,
        FORGOT_PASSWORD: `${API_BASE_URL}/admin/forgot-password`,
        RESET_PASSWORD: `${API_BASE_URL}/admin/reset-password`,
        GOOGLE_LOGIN: `${API_BASE_URL}/admin/google-login`,
        PROFILE: `${API_BASE_URL}/admin/profile`,
    },
    
    // User Management Endpoints
    USERS: {
        LIST: `${API_BASE_URL}/users/`,
        GET: (userId) => `${API_BASE_URL}/users/${userId}`,
        CREATE: `${API_BASE_URL}/users/`,
        UPDATE: (userId) => `${API_BASE_URL}/users/${userId}`,
        DELETE: (userId) => `${API_BASE_URL}/users/${userId}`,
    },
    
    // Resume Management Endpoints
    RESUMES: {
        LIST: `${API_BASE_URL}/resumes/`,
        GET: (resumeId) => `${API_BASE_URL}/resumes/${resumeId}`,
        UPLOAD: `${API_BASE_URL}/resumes/upload`,
        ANALYZE: (resumeId) => `${API_BASE_URL}/resumes/${resumeId}/analyze`,
    },
    
    // Quiz Management Endpoints
    QUIZZES: {
        LIST: `${API_BASE_URL}/quizzes/`,
        GET: (quizId) => `${API_BASE_URL}/quizzes/${quizId}`,
        CREATE: `${API_BASE_URL}/quizzes/`,
        UPDATE: (quizId) => `${API_BASE_URL}/quizzes/${quizId}`,
        DELETE: (quizId) => `${API_BASE_URL}/quizzes/${quizId}`,
    },
    
    // Quiz Scores Endpoints
    QUIZ_SCORES: {
        LIST: `${API_BASE_URL}/quiz-scores/`,
        GET: (scoreId) => `${API_BASE_URL}/quiz-scores/${scoreId}`,
        SUBMIT: `${API_BASE_URL}/quiz-scores/submit`,
        USER_SCORES: (userId) => `${API_BASE_URL}/quiz-scores/user/${userId}`,
    },
    
    // Dashboard and Analytics
    DASHBOARD: {
        STATS: `${API_BASE_URL}/dashboard/stats`,
        ANALYTICS: `${API_BASE_URL}/dashboard/analytics`,
    }
};

// HTTP Methods
const HTTP_METHODS = {
    GET: 'GET',
    POST: 'POST',
    PUT: 'PUT',
    DELETE: 'DELETE',
    PATCH: 'PATCH'
};

// Helper function to make API calls with authentication
async function apiRequest(url, options = {}) {
    const token = localStorage.getItem('adminToken');
    
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json',
            ...(token && { 'Authorization': `Bearer ${token}` })
        },
        ...options
    };
    
    try {
        const response = await fetch(url, defaultOptions);
        
        // Handle unauthorized access
        if (response.status === 401) {
            localStorage.removeItem('adminToken');
            window.location.href = '/login.html';
            throw new Error('Unauthorized access. Please login again.');
        }
        
        return response;
    } catch (error) {
        console.error('API Request Error:', error);
        throw error;
    }
}

// Helper function for GET requests
async function apiGet(url) {
    return apiRequest(url, { method: HTTP_METHODS.GET });
}

// Helper function for POST requests
async function apiPost(url, data) {
    return apiRequest(url, {
        method: HTTP_METHODS.POST,
        body: JSON.stringify(data)
    });
}

// Helper function for POST requests with FormData
async function apiPostForm(url, formData) {
    const token = localStorage.getItem('adminToken');
    
    return fetch(url, {
        method: HTTP_METHODS.POST,
        headers: {
            ...(token && { 'Authorization': `Bearer ${token}` })
        },
        body: formData
    });
}

// Helper function for PUT requests
async function apiPut(url, data) {
    return apiRequest(url, {
        method: HTTP_METHODS.PUT,
        body: JSON.stringify(data)
    });
}

// Helper function for DELETE requests
async function apiDelete(url) {
    return apiRequest(url, { method: HTTP_METHODS.DELETE });
}

// Export configuration and helper functions
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        API_CONFIG,
        HTTP_METHODS,
        apiRequest,
        apiGet,
        apiPost,
        apiPostForm,
        apiPut,
        apiDelete
    };
}
