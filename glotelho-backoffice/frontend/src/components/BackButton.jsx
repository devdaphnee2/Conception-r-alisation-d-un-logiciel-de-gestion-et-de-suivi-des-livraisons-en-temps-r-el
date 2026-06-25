import { useNavigate } from 'react-router-dom';

export default function BackButton({ to }) {
    const navigate = useNavigate();
    return (
        <button
            onClick={() => to ? navigate(to) : navigate(-1)}
            style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', padding: '8px 14px', borderRadius: '10px', border: '1px solid #ECECF2', backgroundColor: 'white', color: '#1C1C2E', fontSize: '13px', fontWeight: 500, cursor: 'pointer', fontFamily: 'Poppins, sans-serif', marginBottom: '20px' }}
        >
            <svg width="16" height="16" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth="2">
                <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
            </svg>
            Retour
        </button>
    );
}