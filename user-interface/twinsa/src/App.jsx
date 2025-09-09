import React, { useState, useEffect } from 'react';
import { Play, Users, Heart, MessageCircle, Settings, Search, Bell, User } from 'lucide-react';

const TwinsaApp = () => {
  const [activeStream, setActiveStream] = useState(null);
  const [chatMessages, setChatMessages] = useState([
    { id: 1, user: 'RetroGamer95', message: 'Salut tout le monde! 🎮', timestamp: '18:45' },
    { id: 2, user: 'NeonQueen', message: 'La qualité est parfaite!', timestamp: '18:46' },
    { id: 3, user: 'PixelMaster', message: 'GG pour ce stream 🔥', timestamp: '18:47' }
  ]);
  const [newMessage, setNewMessage] = useState('');

  const streams = [
    {
      id: 1,
      title: 'Gaming Session Rétro - Arcade Classics',
      streamer: 'RetroGamer95',
      viewers: 1247,
      category: 'Gaming',
      thumbnail: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIwIiBoZWlnaHQ9IjE4MCIgdmlld0JveD0iMCAwIDMyMCAxODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzMjAiIGhlaWdodD0iMTgwIiBmaWxsPSIjMUExQTFBIi8+CjxjaXJjbGUgY3g9IjE2MCIgY3k9IjkwIiByPSI0MCIgZmlsbD0iI0ZGMDA4NyIvPgo8dGV4dCB4PSIxNjAiIHk9Ijk2IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSIgZm9udC1zaXplPSIxNCIgZm9udC1mYW1pbHk9IkFyaWFsIj5HQU1JTkc8L3RleHQ+Cjwvc3ZnPgo=',
      isLive: true
    },
    {
      id: 2,
      title: 'Synthwave Music & Chill Vibes',
      streamer: 'NeonQueen',
      viewers: 892,
      category: 'Music',
      thumbnail: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIwIiBoZWlnaHQ9IjE4MCIgdmlld0JveD0iMCAwIDMyMCAxODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzMjAiIGhlaWdodD0iMTgwIiBmaWxsPSIjMUExQTFBIi8+CjxjaXJjbGUgY3g9IjE2MCIgY3k9IjkwIiByPSI0MCIgZmlsbD0iI0ZGMDA4NyIvPgo8dGV4dCB4PSIxNjAiIHk9Ijk2IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSIgZm9udC1zaXplPSIxNCIgZm9udC1mYW1pbHk9IkFyaWFsIj5NVVNJQzwvdGV4dD4KPHN2Zz4K',
      isLive: true
    },
    {
      id: 3,
      title: 'Art Digital - Création en temps réel',
      streamer: 'PixelMaster',
      viewers: 445,
      category: 'Art',
      thumbnail: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzIwIiBoZWlnaHQ9IjE4MCIgdmlld0JveD0iMCAwIDMyMCAxODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzMjAiIGhlaWdodD0iMTgwIiBmaWxsPSIjMUExQTFBIi8+CjxjaXJjbGUgY3g9IjE2MCIgY3k9IjkwIiByPSI0MCIgZmlsbD0iI0ZGMDA4NyIvPgo8dGV4dCB4PSIxNjAiIHk9Ijk2IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSJ3aGl0ZSIgZm9udC1zaXplPSIxNiIgZm9udC1mYW1pbHk9IkFyaWFsIj5BUlQ8L3RleHQ+Cjwvc3ZnPgo=',
      isLive: true
    }
  ];

  const addMessage = () => {
    if (newMessage.trim()) {
      const message = {
        id: Date.now(),
        user: 'Vous',
        message: newMessage,
        timestamp: new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
      };
      setChatMessages([...chatMessages, message]);
      setNewMessage('');
    }
  };

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="bg-gradient-to-r from-pink-600 to-pink-500 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-black rounded-lg flex items-center justify-center">
                <span className="text-pink-400 font-bold text-lg">TV</span>
              </div>
              <h1 className="text-2xl font-bold text-white tracking-wider">TWINSA</h1>
            </div>
            
            {/* Search */}
            <div className="flex-1 max-w-md mx-8">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-300 w-5 h-5" />
                <input
                  type="text"
                  placeholder="Rechercher des streams..."
                  className="w-full bg-black/20 text-white placeholder-gray-300 pl-10 pr-4 py-2 rounded-lg border border-pink-400/30 focus:border-pink-400 focus:outline-none"
                />
              </div>
            </div>
            
            {/* User Actions */}
            <div className="flex items-center space-x-4">
              <button className="p-2 hover:bg-black/20 rounded-lg transition-colors">
                <Bell className="w-6 h-6" />
              </button>
              <button className="p-2 hover:bg-black/20 rounded-lg transition-colors">
                <Settings className="w-6 h-6" />
              </button>
              <button className="bg-black text-pink-400 px-4 py-2 rounded-lg font-medium hover:bg-gray-900 transition-colors">
                <User className="w-5 h-5 inline mr-2" />
                Connexion
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-3">
            {/* Featured Stream */}
            <div className="mb-8">
              <div className="relative bg-gray-900 rounded-xl overflow-hidden shadow-2xl">
                <div className="aspect-video bg-gradient-to-br from-pink-600/20 to-purple-600/20 flex items-center justify-center">
                  <div className="text-center">
                    <div className="w-20 h-20 bg-pink-500 rounded-full flex items-center justify-center mx-auto mb-4">
                      <Play className="w-8 h-8 text-white ml-1" />
                    </div>
                    <h3 className="text-2xl font-bold mb-2">Stream Principal</h3>
                    <p className="text-gray-400">Cliquez sur un stream pour commencer à regarder</p>
                  </div>
                </div>
                
                {/* Stream Info Overlay */}
                <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <h2 className="text-xl font-bold">En Attente de Stream</h2>
                      <p className="text-gray-300">Sélectionnez un stream pour commencer</p>
                    </div>
                    <div className="flex items-center space-x-4 text-sm">
                      <span className="flex items-center">
                        <Users className="w-4 h-4 mr-1 text-pink-400" />
                        0
                      </span>
                      <button className="flex items-center px-3 py-1 bg-pink-600 rounded-full hover:bg-pink-700 transition-colors">
                        <Heart className="w-4 h-4 mr-1" />
                        Follow
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Stream Grid */}
            <div>
              <h2 className="text-2xl font-bold mb-6 text-pink-400">Streams Live 🔴</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                {streams.map((stream) => (
                  <div
                    key={stream.id}
                    className="bg-gray-900 rounded-lg overflow-hidden shadow-lg hover:shadow-pink-500/20 transition-all duration-300 cursor-pointer transform hover:scale-105"
                    onClick={() => setActiveStream(stream)}
                  >
                    <div className="relative">
                      <img
                        src={stream.thumbnail}
                        alt={stream.title}
                        className="w-full h-40 object-cover"
                      />
                      {stream.isLive && (
                        <span className="absolute top-3 left-3 bg-pink-600 text-white px-2 py-1 rounded text-xs font-bold">
                          LIVE
                        </span>
                      )}
                      <div className="absolute bottom-3 right-3 bg-black/70 text-white px-2 py-1 rounded text-xs">
                        <Users className="w-3 h-3 inline mr-1" />
                        {stream.viewers.toLocaleString()}
                      </div>
                    </div>
                    <div className="p-4">
                      <h3 className="font-bold text-white mb-2 line-clamp-2">{stream.title}</h3>
                      <p className="text-pink-400 text-sm font-medium">{stream.streamer}</p>
                      <p className="text-gray-400 text-sm">{stream.category}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Chat Sidebar */}
          <div className="lg:col-span-1">
            <div className="bg-gray-900 rounded-lg h-full flex flex-col">
              {/* Chat Header */}
              <div className="p-4 border-b border-gray-800">
                <h3 className="font-bold text-pink-400 flex items-center">
                  <MessageCircle className="w-5 h-5 mr-2" />
                  Chat Live
                </h3>
              </div>
              
              {/* Chat Messages */}
              <div className="flex-1 p-4 overflow-y-auto max-h-96">
                {chatMessages.map((msg) => (
                  <div key={msg.id} className="mb-3">
                    <div className="flex items-center space-x-2 mb-1">
                      <span className="text-pink-400 text-sm font-medium">{msg.user}</span>
                      <span className="text-gray-500 text-xs">{msg.timestamp}</span>
                    </div>
                    <p className="text-sm text-gray-300">{msg.message}</p>
                  </div>
                ))}
              </div>
              
              {/* Chat Input */}
              <div className="p-4 border-t border-gray-800">
                <div className="flex space-x-2">
                  <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="Tapez votre message..."
                    className="flex-1 bg-black text-white placeholder-gray-400 px-3 py-2 rounded border border-gray-700 focus:border-pink-400 focus:outline-none text-sm"
                    onKeyPress={(e) => e.key === 'Enter' && addMessage()}
                  />
                  <button
                    onClick={addMessage}
                    className="bg-pink-600 text-white px-4 py-2 rounded hover:bg-pink-700 transition-colors text-sm font-medium"
                  >
                    Envoyer
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-gray-900 border-t border-gray-800 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center">
            <div className="flex items-center justify-center space-x-3 mb-4">
              <div className="w-8 h-8 bg-pink-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">TV</span>
              </div>
              <h2 className="text-xl font-bold text-pink-400">TWINSA</h2>
            </div>
            <p className="text-gray-400 text-sm">
              Plateforme de streaming nouvelle génération - Style rétro, technologie moderne
            </p>
            <div className="mt-4 flex justify-center space-x-6 text-sm text-gray-500">
              <a href="#" className="hover:text-pink-400 transition-colors">À propos</a>
              <a href="#" className="hover:text-pink-400 transition-colors">Conditions</a>
              <a href="#" className="hover:text-pink-400 transition-colors">Confidentialité</a>
              <a href="#" className="hover:text-pink-400 transition-colors">Support</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default TwinsaApp;