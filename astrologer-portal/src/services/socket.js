import { io } from 'socket.io-client'

const SOCKET_URL = import.meta.env.VITE_API_URL || 'https://api.grahvarta.com'

let socket = null

export function getSocket() {
  return socket
}

export function connectSocket(token) {
  if (socket?.connected) return socket

  socket = io(SOCKET_URL, {
    auth: { token },
    transports: ['websocket'],
    reconnection: true,
    reconnectionDelay: 1000,
  })

  socket.on('connect', () => {
    console.log('Socket connected:', socket.id)
    socket.emit('set_role', { role: 'astrologer' })
  })
  socket.on('disconnect', () => console.log('Socket disconnected'))
  socket.on('connect_error', (err) => console.error('Socket error:', err.message))

  return socket
}

export function disconnectSocket() {
  if (socket) {
    socket.disconnect()
    socket = null
  }
}
