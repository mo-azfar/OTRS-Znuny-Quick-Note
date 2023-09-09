# --
# Copyright (C) 202 mo-azfar,https://github.com/mo-azfar/OTRS-Znuny-Quick-Note
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketQuickNote;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # get params
    $Self->{QuickNote} = $ParamObject->GetParam( Param => 'QuickNote' );
    $Self->{CloseNow} = $ParamObject->GetParam( Param => 'CloseNow' );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
	my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(ChannelName => 'Internal');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

	# check permissions
    my $Access = $TicketObject->TicketPermission(
        Type     => 'note',
        TicketID => $Self->{TicketID},
        UserID   => $Self->{UserID}
    );
	
    if ( !$Access )
	{
		return $LayoutObject->ErrorScreen(
            Message => 'Need note permission!',
            Comment => 'Please contact the admin.',
        );
	}

    # check permissions for close now
    if ( $Self->{CloseNow} )
    {
        my $AccessOk = $TicketObject->OwnerCheck(
            TicketID => $Self->{TicketID},
            OwnerID  => $Self->{UserID}
        );

        if ( !$AccessOk )
	    {
		    return $LayoutObject->ErrorScreen(
                Message => 'Need owner!',
                Comment => 'Only ticket owner can perform this.',
            );
	    }

    }
    
	if ( !$Self->{QuickNote} )
	{
		return $LayoutObject->ErrorScreen(
            Message => 'No Quick Note Given!',
            Comment => 'Please contact the admin.',
        );
	}
	
	my %User = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
		UserID => $Self->{UserID},
	);
	
	my $ArticleVisibility = $ConfigObject->Get('Ticket::Frontend::AgentTicketZoom')->{'Widgets'}->{'0099-TicketQuickNote'}->{'IsVisibleForCustomer'};
	
	my $ArticleID = $ArticleBackendObject->ArticleCreate(
		TicketID             => $Self->{TicketID},                 
		SenderType           => "agent",                          
		IsVisibleForCustomer => $ArticleVisibility,                            
		UserID               => $Self->{UserID},                             
		From           => "$User{UserFullname} <$User{UserEmail}>", 
		Subject        => "Feedback from $User{UserFullname}", 
		Body           => $Self->{QuickNote},                 
		ContentType    => "text/plain; charset=ISO-8859-15",      
		HistoryType    => "AddNote",                         
		HistoryComment => "Added note (Note).",
		NoAgentNotify    => 0,                                      
	);
	
    if ( $ArticleID && $Self->{CloseNow} )
    {
        my $State = $ConfigObject->Get('Ticket::Frontend::AgentTicketZoom')->{'Widgets'}->{'0099-TicketQuickNote'}->{'QuickCloseState'};
        
        my $Success = $TicketObject->TicketStateSet(
            State     => $State,
            TicketID  => $Self->{TicketID},
            ArticleID => $ArticleID,
            UserID   => $Self->{UserID},
        );
    }

    #return output
    return $LayoutObject->Redirect(
        OP => "Action=AgentTicketZoom;TicketID=$Self->{TicketID}#$ArticleID",
    );
}

1;