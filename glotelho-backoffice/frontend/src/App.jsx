import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import DashboardLayout from './layouts/DashboardLayout';
import Login from './pages/auth/Login';
import Register from './pages/auth/Register';
import ForgotPassword from './pages/auth/ForgotPassword';
import ResetPassword from './pages/auth/ResetPassword';
import Dashboard from './pages/Dashboard';
import Tracking from './pages/Tracking';
import CommandeList from './pages/CommandeList';
import Recouvrements from './pages/Recouvrements';
import Parametres from './pages/Parametres';
import LivraisonList from './pages/livraisons/LivraisonList';
import LivraisonCreate from './pages/livraisons/LivraisonCreate';
import LivraisonShow from './pages/livraisons/LivraisonShow';
import LivraisonEdit from './pages/livraisons/LivraisonEdit';
import LivreurList from './pages/livreurs/LivreurList';
import LivreurCreate from './pages/livreurs/LivreurCreate';
import LivreurShow from './pages/livreurs/LivreurShow';
import LivreurEdit from './pages/livreurs/LivreurEdit';
import ProfilsEnAttente from './pages/livreurs/ProfilsEnAttente';
import ProfilDetail from './pages/livreurs/ProfilDetail';
import LitigeList from './pages/litiges/LitigeList';
import LitigeCreate from './pages/litiges/LitigeCreate';
import LitigeShow from './pages/litiges/LitigeShow';

function App() {
    return (
        <BrowserRouter>
            <AuthProvider>
                <Routes>
                    <Route path="/login" element={<Login />} />
                    <Route path="/register" element={<Register />} />
                    <Route path="/forgot-password" element={<ForgotPassword />} />
                    <Route path="/reset-password" element={<ResetPassword />} />

                    <Route element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
                        <Route path="/dashboard"            element={<Dashboard />} />
                        <Route path="/tracking"             element={<Tracking />} />
                        <Route path="/commandes"            element={<CommandeList />} />
                        <Route path="/recouvrements"        element={<Recouvrements />} />
                        <Route path="/parametres"           element={<Parametres />} />
                        <Route path="/livraisons"           element={<LivraisonList />} />
                        <Route path="/livraisons/create"    element={<LivraisonCreate />} />
                        <Route path="/livraisons/:id"       element={<LivraisonShow />} />
                        <Route path="/livraisons/:id/edit"  element={<LivraisonEdit />} />
                        <Route path="/livreurs"             element={<LivreurList />} />
                        <Route path="/livreurs/create"      element={<LivreurCreate />} />
                        <Route path="/livreurs/profils"     element={<ProfilsEnAttente />} />
                        <Route path="/livreurs/profils/:id" element={<ProfilDetail />} />
                        <Route path="/livreurs/:id"         element={<LivreurShow />} />
                        <Route path="/livreurs/:id/edit"    element={<LivreurEdit />} />
                        <Route path="/litiges"              element={<LitigeList />} />
                        <Route path="/litiges/create"       element={<LitigeCreate />} />
                        <Route path="/litiges/:id"          element={<LitigeShow />} />
                    </Route>
                    <Route path="*" element={<Navigate to="/dashboard" replace />} />
                </Routes>
            </AuthProvider>
        </BrowserRouter>
    );
}
export default App;