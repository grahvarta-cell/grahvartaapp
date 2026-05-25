import { useEffect, useState, useRef } from 'react'
import { Image, Tag, Heart, MessageCircle, Share2, Pin, Trash2, Plus, X, Send, ChevronDown, ChevronUp } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import api from '../../services/api'
import toast from 'react-hot-toast'
import { formatDistanceToNow } from 'date-fns'

const CATEGORIES = ['astrology', 'tarot', 'meditation', 'numerology', 'vastu', 'general']

export default function CommunityPage() {
  const { user, astrologer } = useAuth()
  const [posts, setPosts] = useState([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [showCompose, setShowCompose] = useState(false)
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [expandedComments, setExpandedComments] = useState({})
  const [comments, setComments] = useState({})
  const [commentInputs, setCommentInputs] = useState({})
  const [loadingComments, setLoadingComments] = useState({})
  const [form, setForm] = useState({ content: '', category: 'astrology', zodiac_sign: '', media_url: '' })
  const textareaRef = useRef(null)

  useEffect(() => { loadPosts() }, [selectedCategory])

  async function loadPosts() {
    setLoading(true)
    try {
      const params = selectedCategory !== 'all' ? `?category=${selectedCategory}` : ''
      const res = await api.get(`/live/community${params}`)
      setPosts(res.data.data || [])
    } catch {
      toast.error('Failed to load posts')
    } finally {
      setLoading(false)
    }
  }

  async function submitPost() {
    if (!form.content.trim()) return toast.error('Post content is required')
    setSubmitting(true)
    try {
      await api.post('/live/community', {
        content: form.content.trim(),
        category: form.category,
        zodiac_sign: form.zodiac_sign || undefined,
        media_url: form.media_url || undefined,
      })
      toast.success('Post published!')
      setForm({ content: '', category: 'astrology', zodiac_sign: '', media_url: '' })
      setShowCompose(false)
      loadPosts()
    } catch {
      toast.error('Failed to publish post')
    } finally {
      setSubmitting(false)
    }
  }

  async function toggleLike(post) {
    try {
      await api.post(`/live/community/${post.id}/like`)
      setPosts(prev => prev.map(p => p.id === post.id
        ? { ...p, is_liked: !p.is_liked, likes_count: p.is_liked ? p.likes_count - 1 : p.likes_count + 1 }
        : p
      ))
    } catch {
      toast.error('Failed to update like')
    }
  }

  async function toggleComments(postId) {
    const isOpen = expandedComments[postId]
    setExpandedComments(prev => ({ ...prev, [postId]: !isOpen }))
    if (!isOpen && !comments[postId]) {
      setLoadingComments(prev => ({ ...prev, [postId]: true }))
      try {
        const res = await api.get(`/live/community/${postId}/comments`)
        setComments(prev => ({ ...prev, [postId]: res.data.data || [] }))
      } catch {
        toast.error('Failed to load comments')
      } finally {
        setLoadingComments(prev => ({ ...prev, [postId]: false }))
      }
    }
  }

  async function submitComment(postId) {
    const text = commentInputs[postId]?.trim()
    if (!text) return
    try {
      const res = await api.post(`/live/community/${postId}/comments`, { content: text })
      setComments(prev => ({ ...prev, [postId]: [...(prev[postId] || []), res.data.data] }))
      setCommentInputs(prev => ({ ...prev, [postId]: '' }))
      setPosts(prev => prev.map(p => p.id === postId ? { ...p, comments_count: p.comments_count + 1 } : p))
    } catch {
      toast.error('Failed to post comment')
    }
  }

  async function deletePost(postId) {
    if (!confirm('Delete this post?')) return
    try {
      await api.delete(`/live/community/${postId}`)
      setPosts(prev => prev.filter(p => p.id !== postId))
      toast.success('Post deleted')
    } catch {
      toast.error('Failed to delete post')
    }
  }

  function sharePost(post) {
    const text = `${post.content.slice(0, 100)}…`
    if (navigator.share) {
      navigator.share({ title: 'AstroVaak Community', text })
    } else {
      navigator.clipboard.writeText(text)
      toast.success('Copied to clipboard')
    }
  }

  const isMyPost = (post) => post.user_id === user?.id || post.astrologer_id === astrologer?.id

  return (
    <div className="space-y-6 pb-20">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold">Community</h1>
          <p className="text-text-secondary text-sm mt-1">Share insights and connect with your audience</p>
        </div>
        <button onClick={() => setShowCompose(true)} className="btn-primary flex items-center gap-2 w-auto px-5">
          <Plus size={18} /> New Post
        </button>
      </div>

      {/* Compose modal */}
      {showCompose && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4">
          <div className="bg-surface rounded-2xl w-full max-w-lg border border-border shadow-2xl">
            <div className="flex items-center justify-between p-5 border-b border-border">
              <h2 className="font-semibold text-lg">Create Post</h2>
              <button onClick={() => setShowCompose(false)} className="text-text-muted hover:text-text-primary">
                <X size={20} />
              </button>
            </div>
            <div className="p-5 space-y-4">
              {/* Author */}
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-orange/20 flex items-center justify-center text-orange font-semibold text-sm shrink-0">
                  {user?.name?.[0]?.toUpperCase()}
                </div>
                <div>
                  <p className="text-sm font-medium">{user?.name}</p>
                  <p className="text-xs text-text-muted">Astrologer · Verified ✓</p>
                </div>
              </div>

              {/* Content */}
              <textarea
                ref={textareaRef}
                value={form.content}
                onChange={e => setForm(f => ({ ...f, content: e.target.value }))}
                rows={5}
                placeholder="Share your astrological insights, predictions, or wisdom…"
                className="w-full bg-background border border-border rounded-xl p-3 text-sm text-text-primary placeholder:text-text-muted resize-none focus:outline-none focus:border-orange"
                autoFocus
              />

              {/* Category & Zodiac */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs text-text-muted mb-1 block">Category</label>
                  <select
                    value={form.category}
                    onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
                    className="w-full bg-background border border-border rounded-xl px-3 py-2 text-sm text-text-primary focus:outline-none focus:border-orange"
                  >
                    {CATEGORIES.map(c => <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>)}
                  </select>
                </div>
                <div>
                  <label className="text-xs text-text-muted mb-1 block">Zodiac Sign (optional)</label>
                  <select
                    value={form.zodiac_sign}
                    onChange={e => setForm(f => ({ ...f, zodiac_sign: e.target.value }))}
                    className="w-full bg-background border border-border rounded-xl px-3 py-2 text-sm text-text-primary focus:outline-none focus:border-orange"
                  >
                    <option value="">All Signs</option>
                    {['Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'].map(s => (
                      <option key={s} value={s}>{s}</option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Media URL */}
              <div>
                <label className="text-xs text-text-muted mb-1 block">Image URL (optional)</label>
                <div className="flex items-center gap-2 bg-background border border-border rounded-xl px-3 py-2">
                  <Image size={14} className="text-text-muted shrink-0" />
                  <input
                    value={form.media_url}
                    onChange={e => setForm(f => ({ ...f, media_url: e.target.value }))}
                    placeholder="https://..."
                    className="flex-1 bg-transparent text-sm text-text-primary placeholder:text-text-muted focus:outline-none"
                  />
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between px-5 pb-5 gap-3">
              <p className="text-xs text-text-muted">{form.content.length} characters</p>
              <div className="flex gap-3">
                <button onClick={() => setShowCompose(false)} className="px-4 py-2 rounded-xl text-sm text-text-secondary border border-border hover:bg-surface-light">
                  Cancel
                </button>
                <button onClick={submitPost} disabled={submitting || !form.content.trim()} className="btn-primary w-auto px-6 text-sm disabled:opacity-50">
                  {submitting ? 'Publishing…' : 'Publish'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Category filter */}
      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
        {['all', ...CATEGORIES].map(cat => (
          <button
            key={cat}
            onClick={() => setSelectedCategory(cat)}
            className={`px-4 py-1.5 rounded-full text-sm font-medium whitespace-nowrap transition-colors ${
              selectedCategory === cat
                ? 'bg-orange text-white'
                : 'bg-surface text-text-secondary hover:bg-surface-light border border-border'
            }`}
          >
            {cat.charAt(0).toUpperCase() + cat.slice(1)}
          </button>
        ))}
      </div>

      {/* Posts */}
      {loading ? (
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 border-2 border-orange border-t-transparent rounded-full animate-spin" />
        </div>
      ) : posts.length === 0 ? (
        <div className="card flex flex-col items-center py-16 gap-4 text-center">
          <div className="w-16 h-16 rounded-2xl bg-orange/10 flex items-center justify-center">
            <MessageCircle size={28} className="text-orange" />
          </div>
          <div>
            <p className="font-semibold text-text-primary">No posts yet</p>
            <p className="text-text-muted text-sm mt-1">Be the first to share something with the community</p>
          </div>
          <button onClick={() => setShowCompose(true)} className="btn-primary w-auto px-6">
            Create First Post
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          {posts.map(post => (
            <div key={post.id} className={`card space-y-4 ${post.is_pinned ? 'border-orange/30' : ''}`}>
              {/* Post header */}
              <div className="flex items-start justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-orange/20 flex items-center justify-center text-orange font-semibold shrink-0">
                    {(post.astrologer_name || post.author_name || 'U')[0].toUpperCase()}
                  </div>
                  <div>
                    <div className="flex items-center gap-1.5">
                      <p className="text-sm font-semibold">{post.astrologer_name || post.author_name}</p>
                      {post.is_verified && <span className="text-orange text-xs">✓</span>}
                      {post.is_pinned && <Pin size={12} className="text-orange" />}
                    </div>
                    <div className="flex items-center gap-2 text-xs text-text-muted">
                      <span className="capitalize">{post.category || 'General'}</span>
                      {post.zodiac_sign && <><span>·</span><span>{post.zodiac_sign}</span></>}
                      <span>·</span>
                      <span>{formatDistanceToNow(new Date(post.created_at), { addSuffix: true })}</span>
                    </div>
                  </div>
                </div>
                {isMyPost(post) && (
                  <button onClick={() => deletePost(post.id)} className="text-text-muted hover:text-error transition-colors p-1">
                    <Trash2 size={15} />
                  </button>
                )}
              </div>

              {/* Content */}
              <p className="text-sm text-text-primary leading-relaxed whitespace-pre-wrap">{post.content}</p>

              {/* Media */}
              {post.media_url && (
                <img src={post.media_url} alt="post media" className="w-full rounded-xl object-cover max-h-80" onError={e => e.target.style.display = 'none'} />
              )}

              {/* Actions */}
              <div className="flex items-center gap-5 pt-1 border-t border-border">
                <button
                  onClick={() => toggleLike(post)}
                  className={`flex items-center gap-1.5 text-sm transition-colors ${post.is_liked ? 'text-error' : 'text-text-muted hover:text-error'}`}
                >
                  <Heart size={16} fill={post.is_liked ? 'currentColor' : 'none'} />
                  <span>{post.likes_count}</span>
                </button>
                <button
                  onClick={() => toggleComments(post.id)}
                  className="flex items-center gap-1.5 text-sm text-text-muted hover:text-orange transition-colors"
                >
                  <MessageCircle size={16} />
                  <span>{post.comments_count}</span>
                  {expandedComments[post.id] ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                </button>
                <button
                  onClick={() => sharePost(post)}
                  className="flex items-center gap-1.5 text-sm text-text-muted hover:text-orange transition-colors ml-auto"
                >
                  <Share2 size={16} />
                  <span>Share</span>
                </button>
              </div>

              {/* Comments section */}
              {expandedComments[post.id] && (
                <div className="space-y-3 pt-2 border-t border-border">
                  {loadingComments[post.id] ? (
                    <div className="flex justify-center py-4">
                      <div className="w-5 h-5 border-2 border-orange border-t-transparent rounded-full animate-spin" />
                    </div>
                  ) : (comments[post.id] || []).length === 0 ? (
                    <p className="text-xs text-text-muted text-center py-2">No comments yet. Be the first!</p>
                  ) : (
                    <div className="space-y-3">
                      {(comments[post.id] || []).map(c => (
                        <div key={c.id} className="flex gap-2.5">
                          <div className="w-7 h-7 rounded-full bg-surface-light flex items-center justify-center text-xs text-text-secondary font-medium shrink-0">
                            {(c.user_name || 'U')[0].toUpperCase()}
                          </div>
                          <div className="bg-background rounded-xl px-3 py-2 flex-1">
                            <p className="text-xs font-medium text-text-primary">{c.user_name}</p>
                            <p className="text-xs text-text-secondary mt-0.5">{c.content}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Comment input */}
                  <div className="flex items-center gap-2 pt-1">
                    <div className="w-7 h-7 rounded-full bg-orange/20 flex items-center justify-center text-orange text-xs font-semibold shrink-0">
                      {user?.name?.[0]?.toUpperCase()}
                    </div>
                    <div className="flex-1 flex items-center gap-2 bg-background border border-border rounded-xl px-3 py-1.5">
                      <input
                        value={commentInputs[post.id] || ''}
                        onChange={e => setCommentInputs(prev => ({ ...prev, [post.id]: e.target.value }))}
                        onKeyDown={e => e.key === 'Enter' && submitComment(post.id)}
                        placeholder="Write a comment…"
                        className="flex-1 bg-transparent text-xs text-text-primary placeholder:text-text-muted focus:outline-none"
                      />
                      <button onClick={() => submitComment(post.id)} className="text-orange hover:text-orange-light transition-colors">
                        <Send size={14} />
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
