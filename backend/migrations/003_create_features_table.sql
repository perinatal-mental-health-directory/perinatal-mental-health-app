-- Create services table
CREATE TABLE services (
                          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                          name VARCHAR(255) NOT NULL,
                          description TEXT NOT NULL,
                          provider_name VARCHAR(255) NOT NULL,
                          contact_email VARCHAR(255),
                          contact_phone VARCHAR(20),
                          website_url VARCHAR(255),
                          address TEXT,
                          service_type VARCHAR(50) NOT NULL CHECK (service_type IN ('online', 'in_person', 'hybrid')),
                          availability_hours JSONB,
                          eligibility_criteria TEXT,
                          is_active BOOLEAN DEFAULT true,
                          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create referrals table
CREATE TABLE referrals (
                           id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                           referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                           referred_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                           service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
                           referral_reason TEXT NOT NULL,
                           urgency_level VARCHAR(20) NOT NULL CHECK (urgency_level IN ('low', 'medium', 'high', 'urgent')),
                           status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'completed', 'cancelled')),
                           notes TEXT,
                           appointment_date TIMESTAMP WITH TIME ZONE,
                           follow_up_required BOOLEAN DEFAULT false,
                           follow_up_date TIMESTAMP WITH TIME ZONE,
                           created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                           updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create feedback table
CREATE TABLE feedback (
                          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                          user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Allow anonymous feedback
                          service_id UUID REFERENCES services(id) ON DELETE CASCADE, -- Optional service-specific feedback
                          rating VARCHAR(20) NOT NULL CHECK (rating IN ('very_dissatisfied', 'dissatisfied', 'neutral', 'satisfied', 'very_satisfied')),
                          title VARCHAR(255) NOT NULL,
                          content TEXT NOT NULL,
                          is_anonymous BOOLEAN DEFAULT false,
                          contact_email VARCHAR(255), -- For anonymous feedback contact
                          status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'addressed', 'archived')),
                          admin_response TEXT,
                          admin_responder_id UUID REFERENCES users(id) ON DELETE SET NULL,
                          response_date TIMESTAMP WITH TIME ZONE,
                          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create resources table
CREATE TABLE resources (
                           id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                           title VARCHAR(255) NOT NULL,
                           description TEXT NOT NULL,
                           content TEXT,
                           resource_type VARCHAR(50) NOT NULL CHECK (resource_type IN ('article', 'video', 'pdf', 'external_link', 'infographic')),
                           url VARCHAR(500),
                           author VARCHAR(255),
                           tags TEXT[], -- Array of tags for searching
                           target_audience VARCHAR(100), -- e.g., 'new_mothers', 'professionals', 'general'
                           estimated_read_time INTEGER, -- In minutes
                           is_featured BOOLEAN DEFAULT false,
                           is_active BOOLEAN DEFAULT true,
                           view_count INTEGER DEFAULT 0,
                           created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                           updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create support_groups table
CREATE TABLE support_groups (
                                id SERIAL PRIMARY KEY,
                                name VARCHAR(255) NOT NULL,
                                category VARCHAR(100) NOT NULL,
                                platform VARCHAR(100) NOT NULL,
                                doctor_info TEXT,
                                guidelines TEXT,
                                is_active BOOLEAN DEFAULT true,
                                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_services_name ON services(name);
CREATE INDEX idx_services_service_type ON services(service_type);
CREATE INDEX idx_services_active ON services(is_active);

CREATE INDEX idx_referrals_user_id ON referrals(referred_user_id);
CREATE INDEX idx_referrals_service_id ON referrals(service_id);
CREATE INDEX idx_referrals_status ON referrals(status);
CREATE INDEX idx_referrals_created_at ON referrals(created_at);

CREATE INDEX idx_feedback_user_id ON feedback(user_id);
CREATE INDEX idx_feedback_rating ON feedback(rating);
CREATE INDEX idx_feedback_created_at ON feedback(created_at);

-- Create indexes for better performance
CREATE INDEX idx_resources_resource_type ON resources(resource_type);
CREATE INDEX idx_resources_is_active ON resources(is_active);
CREATE INDEX idx_resources_is_featured ON resources(is_featured);
CREATE INDEX idx_resources_tags ON resources USING GIN(tags);

CREATE INDEX idx_support_groups_category ON support_groups(category);
CREATE INDEX idx_support_groups_active ON support_groups(is_active);


-- Create triggers to automatically update updated_at
CREATE TRIGGER update_services_updated_at
    BEFORE UPDATE ON services
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_referrals_updated_at
    BEFORE UPDATE ON referrals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feedback_updated_at
    BEFORE UPDATE ON feedback
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_support_groups_updated_at
    BEFORE UPDATE ON support_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

