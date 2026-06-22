import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import DashboardLayout from './layouts/DashboardLayout';
import Login from './pages/auth/Login';
import Dashboard from './pages/Dashboard';
import LivraisonList from './pages/livraisons/LivraisonList';
import LivraisonCreate from './pages/livraisons/LivraisonCreate';
import LivraisonShow from './pages/livraisons/LivraisonShow';
import LivraisonEdit from './pages/livraisons/LivraisonEdit';

function App() {
    return (
        <BrowserRouter>
            <AuthProvider>
                <Routes>
                    <Route path="/login" element={<Login />} />
                    <Route
                        element={
                            <ProtectedRoute>
                                <DashboardLayout />
                            </ProtectedRoute>
                        }
                    >
                        <Route path="/dashboard" element={<Dashboard />} />
                        <Route path="/livraisons" element={<LivraisonList />} />
                        <Route path="/livraisons/create" element={<LivraisonCreate />} />
                        <Route path="/livraisons/:id" element={<LivraisonShow />} />
                        <Route path="/livraisons/:id/edit" element={<LivraisonEdit />} />
                    </Route>
                    <Route path="*" element={<Navigate to="/dashboard" replace />} />
                </Routes>
            </AuthProvider>
        </BrowserRouter>
    );
}

export default App;