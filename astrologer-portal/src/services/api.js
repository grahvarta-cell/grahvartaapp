import axios from 'axios'

const BASE_URL = (import.meta.env.VITE_API_URL || 'https://api.grahvarta.com') + '/api'

const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export const authAPI = {
  register: (data) => api.post('/auth/register', data),
  login: (data) => api.post('/auth/login', data),
  getProfile: () => api.get('/auth/profile'),
  updateProfile: (data) => api.patch('/auth/profile', data),
  uploadAvatar: (file) => {
    const fd = new FormData()
    fd.append('avatar', file)
    return api.post('/auth/avatar', fd, { headers: { 'Content-Type': 'multipart/form-data' } })
  },
}

export const astrologerAPI = {
  register: (data) => api.post('/astrologers/register', data),
  getDashboard: () => api.get('/astrologers/me/dashboard'),
  updateAvailability: (is_available) => api.patch('/astrologers/availability', { is_available }),
  getConsultationHistory: () => api.get('/astrologers/consultations/history'),
  getConsultationMessages: (id) => api.get(`/astrologers/consultations/${id}/messages`),
}

export const liveAPI = {
  getSessions: () => api.get('/live/sessions'),
  createSession: (data) => api.post('/live/sessions', data),
  startSession: (id) => api.patch(`/live/sessions/${id}/start`),
  endSession: (id) => api.patch(`/live/sessions/${id}/end`),
}

export const communityAPI = {
  getPosts: (category) => api.get(`/live/community${category && category !== 'all' ? `?category=${category}` : ''}`),
  createPost: (data) => api.post('/live/community', data),
  deletePost: (id) => api.delete(`/live/community/${id}`),
  toggleLike: (id) => api.post(`/live/community/${id}/like`),
  getComments: (id) => api.get(`/live/community/${id}/comments`),
  addComment: (id, content) => api.post(`/live/community/${id}/comments`, { content }),
}

export const agoraAPI = {
  getToken: (channel, uid = 1) => api.get(`/agora/token?channel=${channel}&uid=${uid}`),
}

export const walletAPI = {
  getWallet: () => api.get('/astrologers/me/wallet'),
  getStats: () => api.get('/astrologers/me/wallet'),
  getTransactions: () => api.get('/astrologers/me/transactions'),
}

export default api
