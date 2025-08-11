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

CREATE TABLE support_groups (
                                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                name VARCHAR(255) NOT NULL,
                                description TEXT NOT NULL,
                                category VARCHAR(50) NOT NULL CHECK (category IN ('postnatal', 'prenatal', 'anxiety', 'depression', 'partner_support', 'general')),
                                platform VARCHAR(50) NOT NULL CHECK (platform IN ('online', 'in_person', 'hybrid')),
                                doctor_info TEXT,
                                url VARCHAR(500),
                                guidelines TEXT,
                                meeting_time VARCHAR(255),
                                max_members INTEGER CHECK (max_members > 0),
                                is_active BOOLEAN DEFAULT true,
                                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE group_memberships (
                                   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                   user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                   group_id UUID NOT NULL REFERENCES support_groups(id) ON DELETE CASCADE,
                                   joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   is_active BOOLEAN DEFAULT true,
                                   role VARCHAR(20) NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin')),
                                   created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                   updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                   UNIQUE(user_id, group_id) -- Prevent duplicate memberships
);

-- Create indexes for better performance
CREATE INDEX idx_support_groups_category ON support_groups(category);
CREATE INDEX idx_support_groups_platform ON support_groups(platform);
CREATE INDEX idx_support_groups_active ON support_groups(is_active);
CREATE INDEX idx_support_groups_created_at ON support_groups(created_at);

CREATE INDEX idx_group_memberships_user_id ON group_memberships(user_id);
CREATE INDEX idx_group_memberships_group_id ON group_memberships(group_id);
CREATE INDEX idx_group_memberships_active ON group_memberships(is_active);
CREATE INDEX idx_group_memberships_joined_at ON group_memberships(joined_at);
CREATE INDEX idx_group_memberships_user_group_active ON group_memberships(user_id, group_id, is_active);

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_support_groups_updated_at
    BEFORE UPDATE ON support_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_group_memberships_updated_at
    BEFORE UPDATE ON group_memberships
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

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


-- Create privacy_preferences table
CREATE TABLE privacy_preferences (
                                     user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
                                     data_tracking_enabled BOOLEAN DEFAULT true,
                                     data_sharing_enabled BOOLEAN DEFAULT false,
                                     cookies_enabled BOOLEAN DEFAULT true,
                                     marketing_emails_enabled BOOLEAN DEFAULT false,
                                     analytics_enabled BOOLEAN DEFAULT true,
                                     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create data_requests table for tracking GDPR requests
CREATE TABLE data_requests (
                               id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                               user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                               request_type VARCHAR(50) NOT NULL CHECK (request_type IN ('data_download', 'account_deletion')),
                               status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
                               reason TEXT,
                               requested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                               processed_at TIMESTAMP WITH TIME ZONE,
                               processed_by UUID REFERENCES users(id) ON DELETE SET NULL,
                               notes TEXT,
                               created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_privacy_preferences_user_id ON privacy_preferences(user_id);
CREATE INDEX idx_data_requests_user_id ON data_requests(user_id);
CREATE INDEX idx_data_requests_type ON data_requests(request_type);
CREATE INDEX idx_data_requests_status ON data_requests(status);
CREATE INDEX idx_data_requests_requested_at ON data_requests(requested_at);

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_privacy_preferences_updated_at
    BEFORE UPDATE ON privacy_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_data_requests_updated_at
    BEFORE UPDATE ON data_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create journey_entries table
CREATE TABLE journey_entries (
                                 id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                 user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                 entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
                                 mood_rating INTEGER NOT NULL CHECK (mood_rating >= 1 AND mood_rating <= 5),
                                 anxiety_level INTEGER CHECK (anxiety_level >= 1 AND anxiety_level <= 5),
                                 sleep_quality INTEGER CHECK (sleep_quality >= 1 AND sleep_quality <= 5),
                                 energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
                                 notes TEXT,
                                 activities TEXT[], -- Array of activities done that day
                                 symptoms TEXT[], -- Array of symptoms experienced
                                 gratitude_note TEXT,
                                 is_private BOOLEAN DEFAULT true,
                                 created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                 updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Ensure one entry per user per day
                                 UNIQUE(user_id, entry_date)
);

-- Create journey_goals table for tracking user goals
CREATE TABLE journey_goals (
                               id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                               user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                               title VARCHAR(255) NOT NULL,
                               description TEXT,
                               target_date DATE,
                               goal_type VARCHAR(50) NOT NULL CHECK (goal_type IN ('mood', 'sleep', 'exercise', 'mindfulness', 'social', 'custom')),
                               status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
                               is_completed BOOLEAN DEFAULT false,
                               completed_at TIMESTAMP WITH TIME ZONE,
                               created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create journey_milestones table for tracking achievements
CREATE TABLE journey_milestones (
                                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                                    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                    milestone_type VARCHAR(50) NOT NULL, -- e.g., 'first_entry', 'week_streak', 'month_complete'
                                    title VARCHAR(255) NOT NULL,
                                    description TEXT,
                                    achieved_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_journey_entries_user_id ON journey_entries(user_id);
CREATE INDEX idx_journey_entries_date ON journey_entries(entry_date);
CREATE INDEX idx_journey_entries_user_date ON journey_entries(user_id, entry_date);
CREATE INDEX idx_journey_entries_mood ON journey_entries(mood_rating);
CREATE INDEX idx_journey_entries_created_at ON journey_entries(created_at);

CREATE INDEX idx_journey_goals_user_id ON journey_goals(user_id);
CREATE INDEX idx_journey_goals_status ON journey_goals(status);
CREATE INDEX idx_journey_goals_type ON journey_goals(goal_type);
CREATE INDEX idx_journey_goals_target_date ON journey_goals(target_date);

CREATE INDEX idx_journey_milestones_user_id ON journey_milestones(user_id);
CREATE INDEX idx_journey_milestones_type ON journey_milestones(milestone_type);
CREATE INDEX idx_journey_milestones_achieved_at ON journey_milestones(achieved_at);

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_journey_entries_updated_at
    BEFORE UPDATE ON journey_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_journey_goals_updated_at
    BEFORE UPDATE ON journey_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();